package com.yourco.pdfgen.model;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record DomainEvent(
    String type,
    String jobId,
    String form,
    Integer compileMs,
    String error
) {
    public static DomainEvent queued(String jobId, String form) {
        return new DomainEvent("job.queued", jobId, form, null, null);
    }

    public static DomainEvent compiled(String jobId, String form, int compileMs) {
        return new DomainEvent("job.compiled", jobId, form, compileMs, null);
    }

    public static DomainEvent failed(String jobId, String form, String error) {
        return new DomainEvent("job.failed", jobId, form, null, error);
    }
}
