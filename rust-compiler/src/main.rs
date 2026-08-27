mod world;

use std::env;
use tonic::{transport::Server, Request, Response, Status};

pub mod compile_proto {
    tonic::include_proto!("typst.compile.v1");
}

use compile_proto::compile_service_server::{CompileService, CompileServiceServer};
use compile_proto::{CompileRequest, CompileResponse, HealthRequest, HealthResponse};

const TYPST_VERSION: &str = "0.12";

struct CompileServiceImpl;

fn diagnostic_message(errors: impl AsRef<[typst::diag::SourceDiagnostic]>) -> String {
    errors
        .as_ref()
        .iter()
        .map(|e| e.message.to_string())
        .collect::<Vec<_>>()
        .join("; ")
}

fn compile_pdf(template_source: String, inputs_json: &str) -> Result<(Vec<u8>, i32), String> {
    let world = world::SingleSourceWorld::new(template_source, inputs_json);
    let compiled = typst::compile(&world);
    let doc = compiled.output.map_err(|errors| {
        format!("typst error: {}", diagnostic_message(&errors))
    })?;

    let pdf_bytes = typst_pdf::pdf(&doc, &typst_pdf::PdfOptions::default()).map_err(|errors| {
        format!("pdf export error: {}", diagnostic_message(&errors))
    })?;

    Ok((pdf_bytes, doc.pages.len() as i32))
}

#[tonic::async_trait]
impl CompileService for CompileServiceImpl {
    async fn compile(
        &self,
        request: Request<CompileRequest>,
    ) -> Result<Response<CompileResponse>, Status> {
        let req = request.into_inner();
        let t0 = std::time::Instant::now();
        let job_id = req.job_id;

        tracing::info!(job_id = %job_id, "compile");

        let result = compile_pdf(req.template_source, &req.inputs_json);
        let compile_ms = t0.elapsed().as_millis() as i32;

        let response = match result {
            Ok((pdf_bytes, pages)) => {
                tracing::info!(job_id = %job_id, pages, compile_ms, "compiled");
                CompileResponse {
                    job_id,
                    pdf_bytes,
                    pages,
                    compile_ms,
                    error: String::new(),
                }
            }
            Err(error) => {
                tracing::error!(job_id = %job_id, error = %error, "compile failed");
                CompileResponse {
                    job_id,
                    pdf_bytes: Vec::new(),
                    pages: 0,
                    compile_ms,
                    error,
                }
            }
        };

        Ok(Response::new(response))
    }

    async fn health(
        &self,
        _request: Request<HealthRequest>,
    ) -> Result<Response<HealthResponse>, Status> {
        Ok(Response::new(HealthResponse {
            ok: true,
            typst_version: TYPST_VERSION.to_string(),
        }))
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    init_tracing();

    let addr: std::net::SocketAddr = env::var("GRPC_ADDR")
        .unwrap_or_else(|_| "0.0.0.0:50051".into())
        .parse()?;
    let max_message_size: usize = env::var("GRPC_MAX_MESSAGE_SIZE")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(20 * 1024 * 1024);

    tracing::info!("gRPC compile sidecar listening on {addr} (typst {TYPST_VERSION})");

    let (mut health_reporter, health_service) = tonic_health::server::health_reporter();
    health_reporter
        .set_serving::<CompileServiceServer<CompileServiceImpl>>()
        .await;

    Server::builder()
        .max_decoding_message_size(max_message_size)
        .max_encoding_message_size(max_message_size)
        .add_service(health_service)
        .add_service(CompileServiceServer::new(CompileServiceImpl))
        .serve(addr)
        .await?;

    Ok(())
}

fn init_tracing() {
    let json = env::var("RUST_LOG_FORMAT")
        .map(|v| v.eq_ignore_ascii_case("json"))
        .unwrap_or(false);
    let filter = tracing_subscriber::EnvFilter::from_default_env();
    if json {
        tracing_subscriber::fmt()
            .json()
            .with_env_filter(filter)
            .init();
    } else {
        tracing_subscriber::fmt()
            .with_env_filter(filter)
            .init();
    }
}
