package com.yourco.pdfgen.service;

import com.yourco.pdfgen.model.JobMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Service
@ConditionalOnProperty(name = "pdfgen.rabbit.enabled", havingValue = "false", matchIfMissing = true)
public class LocalJobPublisher implements JobPublisher {

    private static final Logger log = LoggerFactory.getLogger(LocalJobPublisher.class);

    private final JobService jobService;
    private final ExecutorService executor = Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "pdfgen-local-job");
        t.setDaemon(true);
        return t;
    });

    public LocalJobPublisher(JobService jobService) {
        this.jobService = jobService;
    }

    @Override
    public void enqueue(JobMessage message) {
        executor.execute(() -> {
            try {
                jobService.compileAndStore(
                        message.jobId(),
                        message.form(),
                        message.version(),
                        message.fields()
                );
            } catch (Exception e) {
                log.error("Local job {} failed: {}", message.jobId(), e.getMessage());
            }
        });
    }
}
