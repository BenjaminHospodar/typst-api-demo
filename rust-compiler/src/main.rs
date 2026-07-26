mod world;
mod worker;

use redis::Client;
use tokio::task::JoinSet;
use std::env;
use tonic::{transport::Server, Request, Response, Status};

pub mod compile_proto {
    tonic::include_proto!("typst.compile.v1");
}

use compile_proto::compile_service_server::{CompileService, CompileServiceServer};
use compile_proto::{
    CompileRequest, CompileResponse,
    HealthRequest, HealthResponse,
};

pub struct CompileServiceImpl {
    redis_client: Client,
}

#[tonic::async_trait]
impl CompileService for CompileServiceImpl {
    async fn compile(
        &self,
        request: Request<CompileRequest>,
    ) -> Result<Response<CompileResponse>, Status> {
        let req = request.into_inner();
        let t0 = std::time::Instant::now();

        let world = world::SingleSourceWorld::new(req.typ_source);
        let compiled = typst::compile(&world);

        let doc = compiled.output.map_err(|errors| {
            let msg = errors.iter()
                .map(|e| e.message.to_string())
                .collect::<Vec<_>>()
                .join("; ");
            Status::invalid_argument(format!("typst error: {}", msg))
        })?;

        let pdf_bytes = typst_pdf::pdf(&doc, &typst_pdf::PdfOptions::default())
            .map_err(|errors| {
                let msg = errors.iter()
                    .map(|e| e.message.to_string())
                    .collect::<Vec<_>>()
                    .join("; ");
                Status::internal(format!("pdf export error: {}", msg))
            })?;
        let compile_ms = t0.elapsed().as_millis() as i32;

        Ok(Response::new(CompileResponse {
            job_id: req.job_id,
            pdf_bytes: pdf_bytes,
            pages: doc.pages.len() as i32,
            compile_ms,
        }))
    }

    async fn health(
        &self,
        _request: Request<HealthRequest>,
    ) -> Result<Response<HealthResponse>, Status> {
        // Check Redis queue depth
        let queue_depth = match self.redis_client.get_multiplexed_async_connection().await {
            Ok(mut conn) => {
                let len: i32 = redis::cmd("XLEN")
                    .arg("pdf:jobs")
                    .query_async(&mut conn)
                    .await
                    .unwrap_or(0);
                len
            }
            Err(_) => -1,
        };

        Ok(Response::new(HealthResponse {
            ok: true,
            typst_version: "0.12".to_string(),
            queue_depth,
        }))
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let redis_url = env::var("REDIS_URL").unwrap_or_else(|_| "redis://redis:6379".into());
    let worker_count: usize = env::var("WORKER_THREADS")
        .unwrap_or_else(|_| "4".into())
        .parse()?;

    let client = Client::open(redis_url)?;

    // Ensure consumer group exists
    {
        let mut conn = client.get_multiplexed_async_connection().await?;
        let _: Result<(), _> = redis::cmd("XGROUP")
            .arg("CREATE")
            .arg("pdf:jobs")
            .arg("typst-workers")
            .arg("$")
            .arg("MKSTREAM")
            .query_async(&mut conn)
            .await;
    }

    tracing::info!("Starting {} worker threads", worker_count);

    let mut set = JoinSet::new();

    for i in 0..worker_count {
        let conn = client.get_multiplexed_async_connection().await?;
        let worker_id = format!("worker-{}", i);
        set.spawn(async move {
            worker::run_worker(conn, worker_id).await;
        });
    }

    // gRPC health/compile server on port 50051
    let grpc_client = client.clone();
    set.spawn(async move {
        let addr = "0.0.0.0:50051".parse().unwrap();
        tracing::info!("gRPC server listening on {}", addr);
        Server::builder()
            .add_service(CompileServiceServer::new(CompileServiceImpl {
                redis_client: grpc_client,
            }))
            .serve(addr)
            .await
            .unwrap();
    });

    while let Some(res) = set.join_next().await {
        if let Err(e) = res {
            tracing::error!("Worker panicked: {}", e);
        }
    }

    Ok(())
}
