package com.yourco.pdfgen.service;

import com.yourco.pdfgen.config.PdfGenProperties;
import com.yourco.pdfgen.model.DomainEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(name = "pdfgen.rabbit.enabled", havingValue = "true")
public class RabbitEventPublisher implements EventPublisher {

    private static final Logger log = LoggerFactory.getLogger(RabbitEventPublisher.class);

    private final RabbitTemplate rabbitTemplate;
    private final String eventsExchange;

    public RabbitEventPublisher(RabbitTemplate rabbitTemplate, PdfGenProperties props) {
        this.rabbitTemplate = rabbitTemplate;
        this.eventsExchange = props.rabbit().eventsExchange();
    }

    @Override
    public void publish(DomainEvent event) {
        try {
            rabbitTemplate.convertAndSend(eventsExchange, event.type(), event);
        } catch (Exception e) {
            log.warn("Failed to publish {} for job {}: {}", event.type(), event.jobId(), e.getMessage());
        }
    }
}
