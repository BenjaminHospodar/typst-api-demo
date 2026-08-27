package com.yourco.pdfgen.service;

import com.yourco.pdfgen.exception.CompileException;
import com.yourco.pdfgen.exception.InvalidRequestException;
import com.yourco.pdfgen.exception.PayloadTooLargeException;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.exception.TemplateNotFoundException;
import com.yourco.pdfgen.model.JobMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "pdfgen.rabbit.enabled", havingValue = "true")
public class JobWorker {

    private static final Logger log = LoggerFactory.getLogger(JobWorker.class);

    private final JobService jobService;

    public JobWorker(JobService jobService) {
        this.jobService = jobService;
    }

    @RabbitListener(queues = "${pdfgen.rabbit.jobs-queue}")
    public void processJob(JobMessage message) {
        log.info("Processing async job {}", message.jobId());
        try {
            jobService.compileAndStore(
                    message.jobId(),
                    message.form(),
                    message.version(),
                    message.fields()
            );
        } catch (CompileException | PayloadTooLargeException | InvalidRequestException | TemplateNotFoundException e) {
            log.warn("Job {} failed permanently: {}", message.jobId(), e.getMessage());
        } catch (ServiceUnavailableException e) {
            if (!e.isRetryable()) {
                log.warn("Job {} failed without retry: {}", message.jobId(), e.getMessage());
                return;
            }
            log.error("Job {} hit a retryable compiler error: {}", message.jobId(), e.getMessage());
            throw e;
        } catch (RuntimeException e) {
            log.error("Job {} failed unexpectedly: {}", message.jobId(), e.getMessage());
            throw e;
        }
    }
}
