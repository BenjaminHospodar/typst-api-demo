package com.yourco.pdfgen.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.f4b6a3.ulid.UlidCreator;
import com.yourco.pdfgen.exception.CompileException;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.model.Job;
import com.yourco.pdfgen.repository.JobRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.connection.stream.MapRecord;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.TimeoutException;

@Service
public class JobService {

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final JobRepository jobRepository;

    private static final String STREAM     = "pdf:jobs";
    private static final String STATUS_KEY = "pdf:status:";
    private static final String RESULT_KEY = "pdf:result:";

    @Value("${pdfgen.queue.max-depth:10000}")
    private long maxQueueDepth;

    public JobService(StringRedisTemplate redis, ObjectMapper objectMapper, JobRepository jobRepository) {
        this.redis = redis;
        this.objectMapper = objectMapper;
        this.jobRepository = jobRepository;
    }

    public String enqueue(String form, String version, Map<String, String> fields)
            throws JsonProcessingException {

        // Back-pressure: reject if queue is too deep
        Long queueDepth = redis.opsForStream().size(STREAM);
        if (queueDepth != null && queueDepth > maxQueueDepth) {
            throw new ServiceUnavailableException("Queue full, retry later");
        }

        String jobId = UlidCreator.getUlid().toString();

        Map<String, String> message = Map.of(
                "job_id",      jobId,
                "form",        form,
                "version",     version,
                "fields_json", objectMapper.writeValueAsString(fields)
        );

        redis.opsForStream().add(MapRecord.create(STREAM, message));
        redis.opsForValue().set(STATUS_KEY + jobId, "pending", Duration.ofMinutes(5));

        // Audit log
        Job job = new Job();
        job.setId(jobId);
        job.setForm(form);
        job.setVersion(version);
        job.setStatus("pending");
        jobRepository.save(job);

        return jobId;
    }

    /**
     * Poll Redis for result with timeout. Used for synchronous response path.
     */
    public byte[] awaitResult(String jobId, Duration timeout)
            throws TimeoutException, InterruptedException {

        Instant deadline = Instant.now().plus(timeout);

        while (Instant.now().isBefore(deadline)) {
            String status = redis.opsForValue().get(STATUS_KEY + jobId);

            if ("done".equals(status)) {
                byte[] pdf = redis.execute(connection -> {
                    byte[] raw = connection.stringCommands().get((RESULT_KEY + jobId).getBytes());
                    return raw;
                }, true);
                if (pdf != null) return pdf;
            }
            if ("error".equals(status)) {
                throw new CompileException("Compile failed for job " + jobId);
            }
            Thread.sleep(5);
        }
        throw new TimeoutException("Job " + jobId + " timed out");
    }

    /**
     * Non-blocking check — for poll endpoint.
     */
    public String getStatus(String jobId) {
        return redis.opsForValue().get(STATUS_KEY + jobId);
    }

    public byte[] getResult(String jobId) {
        return redis.execute(connection -> {
            return connection.stringCommands().get((RESULT_KEY + jobId).getBytes());
        }, true);
    }
}
