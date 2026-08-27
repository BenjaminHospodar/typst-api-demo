package com.yourco.pdfgen.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.f4b6a3.ulid.UlidCreator;
import com.yourco.pdfgen.exception.CompileException;
import com.yourco.pdfgen.exception.PayloadTooLargeException;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.model.DomainEvent;
import com.yourco.pdfgen.model.Job;
import com.yourco.pdfgen.repository.JobRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.locks.LockSupport;

@Service
public class JobService {

    private static final Logger log = LoggerFactory.getLogger(JobService.class);
    private static final String STATUS_KEY = "pdf:status:";
    private static final String RESULT_KEY = "pdf:result:";
    private static final String ERROR_KEY = "pdf:error:";
    private static final Duration RESULT_TTL = Duration.ofMinutes(5);

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final JobRepository jobRepository;
    private final CompilerService compilerService;
    private final TemplateService templateService;
    private final FieldValidator fieldValidator;
    private final EventPublisher eventPublisher;

    public JobService(StringRedisTemplate redis,
                      ObjectMapper objectMapper,
                      JobRepository jobRepository,
                      CompilerService compilerService,
                      TemplateService templateService,
                      FieldValidator fieldValidator,
                      EventPublisher eventPublisher) {
        this.redis = redis;
        this.objectMapper = objectMapper;
        this.jobRepository = jobRepository;
        this.compilerService = compilerService;
        this.templateService = templateService;
        this.fieldValidator = fieldValidator;
        this.eventPublisher = eventPublisher;
    }

    public String newJobId() {
        return UlidCreator.getUlid().toString();
    }

    public String createJob(String jobId, String form, String version, Map<String, String> fields) {
        Job job = new Job();
        job.setId(jobId);
        job.setForm(form);
        job.setVersion(version);
        job.setStatus("pending");
        jobRepository.save(job);

        redis.opsForValue().set(STATUS_KEY + jobId, "pending", RESULT_TTL);
        eventPublisher.publish(DomainEvent.queued(jobId, form));
        return jobId;
    }

    public byte[] compileAndStore(String jobId, String form, String version, Map<String, String> fields) {
        redis.opsForValue().set(STATUS_KEY + jobId, "compiling", RESULT_TTL);
        jobRepository.findById(jobId).ifPresent(job -> {
            job.setStatus("compiling");
            job.setStartedAt(Instant.now());
            jobRepository.save(job);
        });

        try {
            TemplateService.CachedTemplate template = templateService.getTemplate(form, version);
            String inputsJson;
            try {
                inputsJson = objectMapper.writeValueAsString(fields);
            } catch (JsonProcessingException e) {
                throw new CompileException("Failed to serialize fields", e);
            }

            CompileResult result = compilerService.compile(jobId, template.typSource(), inputsJson);
            fieldValidator.validatePdf(result.pdfBytes());

            redis.execute(connection -> {
                connection.stringCommands().setEx(
                        (RESULT_KEY + jobId).getBytes(),
                        RESULT_TTL.toSeconds(),
                        result.pdfBytes()
                );
                return null;
            }, true);
            redis.opsForValue().set(STATUS_KEY + jobId, "done", RESULT_TTL);
            redis.delete(ERROR_KEY + jobId);

            jobRepository.findById(jobId).ifPresent(job -> {
                job.setStatus("done");
                job.setFinishedAt(Instant.now());
                job.setPageCount(result.pages());
                job.setCompileMs(result.compileMs());
                jobRepository.save(job);
            });

            eventPublisher.publish(DomainEvent.compiled(jobId, form, result.compileMs()));
            return result.pdfBytes();
        } catch (RuntimeException e) {
            storeFailure(jobId, form, e);
            throw e;
        }
    }

    public void markFailed(String jobId, String form, String message) {
        storeFailure(jobId, form, new ServiceUnavailableException(message, true));
    }

    public byte[] awaitResult(String jobId, long timeoutMs) throws TimeoutException {
        long deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(Math.max(timeoutMs, 0));
        while (true) {
            String status = redis.opsForValue().get(STATUS_KEY + jobId);
            if ("done".equals(status)) {
                byte[] pdf = getResult(jobId);
                if (pdf != null) {
                    return pdf;
                }
            }
            if ("error".equals(status)) {
                throwStoredError(jobId);
            }
            if (System.nanoTime() >= deadline) {
                throw new TimeoutException("Sync wait expired for job " + jobId);
            }
            LockSupport.parkNanos(TimeUnit.MILLISECONDS.toNanos(25));
        }
    }

    public void rethrowIfFailed(String jobId) {
        String status = getStatus(jobId);
        if ("error".equals(status)) {
            throwStoredError(jobId);
        }
    }

    public String getStatus(String jobId) {
        String cached = redis.opsForValue().get(STATUS_KEY + jobId);
        if (cached != null) {
            return cached;
        }
        return jobRepository.findById(jobId).map(Job::getStatus).orElse(null);
    }

    public byte[] getResult(String jobId) {
        return redis.execute(connection ->
                connection.stringCommands().get((RESULT_KEY + jobId).getBytes()), true);
    }

    private void storeFailure(String jobId, String form, RuntimeException e) {
        String encoded = encodeError(e);
        redis.opsForValue().set(STATUS_KEY + jobId, "error", RESULT_TTL);
        redis.opsForValue().set(ERROR_KEY + jobId, encoded, RESULT_TTL);
        jobRepository.findById(jobId).ifPresent(job -> {
            job.setStatus("error");
            job.setFinishedAt(Instant.now());
            job.setErrorMsg(e.getMessage());
            jobRepository.save(job);
        });
        eventPublisher.publish(DomainEvent.failed(jobId, form, e.getMessage()));
        log.warn("Job {} failed: {}", jobId, e.getMessage());
    }

    private void throwStoredError(String jobId) {
        String raw = redis.opsForValue().get(ERROR_KEY + jobId);
        if (raw == null || raw.isBlank()) {
            throw new CompileException("compile failed");
        }
        int split = raw.indexOf(':');
        String kind = split < 0 ? "compile" : raw.substring(0, split);
        String message = split < 0 ? raw : raw.substring(split + 1);
        switch (kind) {
            case "unavailable" -> throw new ServiceUnavailableException(message, true);
            case "unavailable-final" -> throw new ServiceUnavailableException(message, false);
            case "payload" -> throw new PayloadTooLargeException(message);
            default -> throw new CompileException(message);
        }
    }

    private static String encodeError(RuntimeException e) {
        String kind = "compile";
        if (e instanceof PayloadTooLargeException) {
            kind = "payload";
        } else if (e instanceof ServiceUnavailableException sue) {
            kind = sue.isRetryable() ? "unavailable" : "unavailable-final";
        }
        String message = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
        return kind + ":" + message;
    }
}
