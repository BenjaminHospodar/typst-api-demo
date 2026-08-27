package com.yourco.pdfgen.controller;

import com.yourco.pdfgen.config.PdfGenProperties;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.model.GenerateRequest;
import com.yourco.pdfgen.model.JobMessage;
import com.yourco.pdfgen.service.FieldValidator;
import com.yourco.pdfgen.service.IdempotencyService;
import com.yourco.pdfgen.service.JobPublisher;
import com.yourco.pdfgen.service.JobService;
import com.yourco.pdfgen.service.TemplateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.concurrent.TimeoutException;

@RestController
@RequestMapping("/api/v1")
@Validated
@Tag(name = "PDF Generation")
@SecurityRequirement(name = "ApiKeyAuth")
public class GenerateController {

    private final TemplateService templateService;
    private final JobService jobService;
    private final JobPublisher jobPublisher;
    private final FieldValidator fieldValidator;
    private final IdempotencyService idempotencyService;
    private final int syncTimeoutMs;

    public GenerateController(TemplateService templateService,
                              JobService jobService,
                              JobPublisher jobPublisher,
                              FieldValidator fieldValidator,
                              IdempotencyService idempotencyService,
                              PdfGenProperties props) {
        this.templateService = templateService;
        this.jobService = jobService;
        this.jobPublisher = jobPublisher;
        this.fieldValidator = fieldValidator;
        this.idempotencyService = idempotencyService;
        this.syncTimeoutMs = props.queue().syncTimeoutMs();
    }

    @PostMapping("/generate")
    @Operation(summary = "Generate a PDF from a Typst template")
    public ResponseEntity<?> generate(
            @RequestBody @Valid GenerateRequest req,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey)
            throws Exception {

        TemplateService.CachedTemplate template = templateService.getTemplate(req.form(), req.version());
        fieldValidator.validateTemplate(template.typSource());
        fieldValidator.validateFields(req.fields());
        fieldValidator.validateAgainstSchema(template.schema(), req.fields());

        String jobId = jobService.newJobId();
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            String claimed = idempotencyService.claim(idempotencyKey, jobId);
            if (!jobId.equals(claimed)) {
                return resolveExistingJob(claimed, req.form());
            }
        }

        jobService.createJob(jobId, req.form(), req.version(), req.fields());
        try {
            jobPublisher.enqueue(new JobMessage(jobId, req.form(), req.version(), req.fields()));
        } catch (RuntimeException e) {
            jobService.markFailed(jobId, req.form(), e.getMessage());
            if (e instanceof ServiceUnavailableException) {
                throw e;
            }
            throw new ServiceUnavailableException("Failed to enqueue job", e, true);
        }

        try {
            byte[] pdf = jobService.awaitResult(jobId, syncTimeoutMs);
            return pdfResponse(req.form(), pdf);
        } catch (TimeoutException e) {
            return ResponseEntity.accepted().body(Map.of(
                    "job_id", jobId,
                    "poll_url", "/api/v1/jobs/" + jobId + "/result"
            ));
        }
    }

    private ResponseEntity<?> resolveExistingJob(String jobId, String form) throws Exception {
        String status = jobService.getStatus(jobId);
        if ("done".equals(status)) {
            byte[] pdf = jobService.getResult(jobId);
            if (pdf != null) {
                return pdfResponse(form, pdf);
            }
            return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
                    "error", "PDF expired from cache",
                    "job_id", jobId
            ));
        }
        if ("error".equals(status)) {
            jobService.rethrowIfFailed(jobId);
            return ResponseEntity.unprocessableEntity()
                    .body(Map.of("status", "error", "job_id", jobId));
        }
        return ResponseEntity.accepted().body(Map.of(
                "job_id", jobId,
                "poll_url", "/api/v1/jobs/" + jobId + "/result"
        ));
    }

    @GetMapping("/jobs/{jobId}/result")
    @Operation(summary = "Poll for async PDF generation result")
    public ResponseEntity<?> pollResult(@PathVariable String jobId) {
        String status = jobService.getStatus(jobId);

        if (status == null) {
            return ResponseEntity.notFound().build();
        }

        if ("done".equals(status)) {
            byte[] pdf = jobService.getResult(jobId);
            if (pdf != null) {
                return pdfResponse("result", pdf);
            }
            return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
                    "error", "PDF expired from cache",
                    "job_id", jobId
            ));
        }

        if ("error".equals(status)) {
            jobService.rethrowIfFailed(jobId);
            return ResponseEntity.unprocessableEntity()
                    .body(Map.of("status", "error", "job_id", jobId));
        }

        return ResponseEntity.accepted().body(Map.of(
                "status", status,
                "job_id", jobId,
                "poll_url", "/api/v1/jobs/" + jobId + "/result"
        ));
    }

    private static ResponseEntity<byte[]> pdfResponse(String form, byte[] pdf) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_PDF_VALUE)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "inline; filename=\"" + form + ".pdf\"")
                .body(pdf);
    }
}
