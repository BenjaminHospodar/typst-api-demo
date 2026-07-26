use redis::AsyncCommands;
use redis::aio::MultiplexedConnection;
use crate::world::SingleSourceWorld;

const STREAM: &str = "pdf:jobs";
const GROUP: &str = "typst-workers";
const RESULT_TTL: u64 = 300; // 5 minutes

pub async fn run_worker(mut conn: MultiplexedConnection, worker_id: String) {
    tracing::info!("Worker {} started", worker_id);

    loop {
        let messages: redis::streams::StreamReadReply = conn
            .xread_options(
                &[STREAM],
                &[">"],
                &redis::streams::StreamReadOptions::default()
                    .group(GROUP, &worker_id)
                    .count(1)
                    .block(100),
            )
            .await
            .unwrap_or_default();

        for stream_key in &messages.keys {
            for entry in &stream_key.ids {
                let job_id: String = entry.get("job_id").unwrap_or_default();
                let form: String = entry.get("form").unwrap_or_default();
                let version: String = entry.get("version").unwrap_or_default();
                let fields_json: String = entry.get("fields_json").unwrap_or_default();

                tracing::info!(job_id = %job_id, form = %form, "compiling");

                // Set status to compiling
                let _: Result<(), _> = conn.set_ex::<_, _, ()>(
                    format!("pdf:status:{}", job_id), "compiling", RESULT_TTL
                ).await;

                match compile_job(&mut conn, &job_id, &form, &version, &fields_json).await {
                    Ok(_) => {
                        let _: Result<(), _> = conn.set_ex::<_, _, ()>(
                            format!("pdf:status:{}", job_id), "done", RESULT_TTL
                        ).await;
                        tracing::info!(job_id = %job_id, "done");
                    }
                    Err(e) => {
                        tracing::error!(job_id = %job_id, error = %e, "compile failed");
                        let _: Result<(), _> = conn.set_ex::<_, _, ()>(
                            format!("pdf:status:{}", job_id), "error", RESULT_TTL
                        ).await;
                    }
                }

                // ACK — remove from pending list
                let _: Result<(), _> = conn.xack::<_, _, _, ()>(STREAM, GROUP, &[&entry.id]).await;
            }
        }
    }
}

async fn compile_job(
    conn: &mut MultiplexedConnection,
    job_id: &str,
    form: &str,
    version: &str,
    fields_json: &str,
) -> anyhow::Result<()> {
    let t0 = std::time::Instant::now();

    // 1. Fetch template from Redis
    let template_key = format!("template:{}:{}", form, version);
    let typ_template: String = conn.get(&template_key).await
        .map_err(|_| anyhow::anyhow!("template {} {} not in Redis", form, version))?;

    // 2. Build vars block from fields JSON
    let fields: std::collections::HashMap<String, String> =
        serde_json::from_str(fields_json)?;
    let vars_block = build_vars_block(&fields);

    // 3. Merge: prepend vars block to template
    let full_source = format!("{}\n{}", vars_block, typ_template);

    // 4. Compile with embedded Typst (no subprocess)
    let world = SingleSourceWorld::new(full_source);
    let compiled = typst::compile(&world);

    let doc = compiled.output.map_err(|errors| {
        let msg = errors.iter()
            .map(|e| e.message.to_string())
            .collect::<Vec<_>>()
            .join("; ");
        anyhow::anyhow!("typst error: {}", msg)
    })?;

    let pdf_bytes = typst_pdf::pdf(&doc, &typst_pdf::PdfOptions::default())
        .map_err(|errors| {
            let msg = errors.iter()
                .map(|e| e.message.to_string())
                .collect::<Vec<_>>()
                .join("; ");
            anyhow::anyhow!("pdf export error: {}", msg)
        })?;
    let compile_ms = t0.elapsed().as_millis() as i64;
    tracing::info!(job_id = %job_id, compile_ms = %compile_ms, "compiled");

    // 5. Write result to Redis
    conn.set_ex::<_, _, ()>(
        format!("pdf:result:{}", job_id),
        pdf_bytes.as_slice(),
        RESULT_TTL,
    ).await?;

    Ok(())
}

fn build_vars_block(fields: &std::collections::HashMap<String, String>) -> String {
    let mut block = String::from("// --- GENERATED VARS ---\n#let vars = (\n");
    for (key, val) in fields {
        // Escape backslashes and double quotes inside the Typst string
        let escaped = val.replace('\\', "\\\\").replace('"', "\\\"");
        block.push_str(&format!("  {}: \"{}\",\n", key, escaped));
    }
    block.push_str(")\n// --- END VARS ---\n");
    block
}
