package com.yourco.pdfgen.service;

import com.yourco.pdfgen.model.DomainEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(name = "pdfgen.rabbit.enabled", havingValue = "false", matchIfMissing = true)
public class NoOpEventPublisher implements EventPublisher {

    private static final Logger log = LoggerFactory.getLogger(NoOpEventPublisher.class);

    @Override
    public void publish(DomainEvent event) {
        log.debug("event {} job_id={}", event.type(), event.jobId());
    }
}
