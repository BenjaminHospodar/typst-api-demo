package com.yourco.pdfgen.service;

import com.yourco.pdfgen.config.PdfGenProperties;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.model.JobMessage;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(name = "pdfgen.rabbit.enabled", havingValue = "true")
public class RabbitJobPublisher implements JobPublisher {

    private final RabbitTemplate rabbitTemplate;
    private final String jobsExchange;
    private final String jobsRoutingKey;

    public RabbitJobPublisher(RabbitTemplate rabbitTemplate, PdfGenProperties props) {
        this.rabbitTemplate = rabbitTemplate;
        this.jobsExchange = props.rabbit().jobsExchange();
        this.jobsRoutingKey = props.rabbit().jobsRoutingKey();
    }

    @Override
    public void enqueue(JobMessage message) {
        try {
            rabbitTemplate.convertAndSend(jobsExchange, jobsRoutingKey, message);
        } catch (Exception e) {
            throw new ServiceUnavailableException("Failed to enqueue job " + message.jobId(), e, true);
        }
    }
}
