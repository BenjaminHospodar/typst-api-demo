package com.yourco.pdfgen.controller;

import com.yourco.pdfgen.model.GenerateRequest;
import com.yourco.pdfgen.service.JobService;
import com.yourco.pdfgen.service.TemplateService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.TimeoutException;

@RestController
@RequestMapping("/api/v1")
@Validated
public class GenerateController {

    private final TemplateService templateService;
    private final JobService jobService;

    @Value("${pdfgen.queue.sync-timeout-ms:30}")
    private int syncTimeoutMs;

    public GenerateController(TemplateService templateService, JobService jobService) {
        this.templateService = templateService;
        this.jobService = jobService;
    }

    @PostMapping("/generate")
    public ResponseEntity<?> generate(@RequestBody @Valid GenerateRequest req)
            throws Exception {

        // Validate template exists (also warms Redis cache)
        templateService.getTypSource(req.form(), req.version());

        // Enqueue job
        String jobId = jobService.enqueue(req.form(), req.version(), req.fields());

        // Await result (short timeout for sync response)
        try {
            byte[] pdf = jobService.awaitResult(jobId, Duration.ofMillis(syncTimeoutMs));
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_PDF_VALUE)
                    .header(HttpHeaders.CONTENT_DISPOSITION,
                            "inline; filename=\"" + req.form() + ".pdf\"")
                    .body(pdf);
        } catch (TimeoutException e) {
            // Fall back to async — return 202 + job_id
            return ResponseEntity.accepted().body(Map.of(
                    "job_id", jobId,
                    "poll_url", "/api/v1/jobs/" + jobId + "/result"
            ));
        }
    }

    @GetMapping("/jobs/{jobId}/result")
    public ResponseEntity<?> pollResult(@PathVariable String jobId) {
        String status = jobService.getStatus(jobId);

        if (status == null) {
            return ResponseEntity.notFound().build();
        }

        if ("done".equals(status)) {
            byte[] pdf = jobService.getResult(jobId);
            if (pdf != null) {
                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_PDF_VALUE)
                        .header(HttpHeaders.CONTENT_DISPOSITION,
                                "inline; filename=\"result.pdf\"")
                        .body(pdf);
            }
        }

        if ("error".equals(status)) {
            return ResponseEntity.unprocessableEntity()
                    .body(Map.of("status", "error", "job_id", jobId));
        }

        // Still pending
        return ResponseEntity.accepted().body(Map.of(
                "status", status,
                "job_id", jobId,
                "poll_url", "/api/v1/jobs/" + jobId + "/result"
        ));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "ok"));
    }
}
