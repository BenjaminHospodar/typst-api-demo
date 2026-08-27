package com.yourco.pdfgen.service;

import com.yourco.pdfgen.model.DomainEvent;

public interface EventPublisher {
    void publish(DomainEvent event);
}
