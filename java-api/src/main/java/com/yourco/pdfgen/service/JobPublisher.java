package com.yourco.pdfgen.service;

import com.yourco.pdfgen.model.JobMessage;

public interface JobPublisher {
    void enqueue(JobMessage message);
}
