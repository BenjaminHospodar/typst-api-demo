package com.yourco.pdfgen.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pdfgen")
public record PdfGenProperties(
    String apiKey,
    Compiler compiler,
    Queue queue,
    Limits limits,
    Rabbit rabbit
) {
    public record Compiler(String host, int port, long deadlineMs, int maxMessageSize) {}
    public record Queue(int syncTimeoutMs) {}
    public record Limits(
        int maxTemplateBytes,
        int maxFieldCount,
        int maxFieldKeyLength,
        int maxFieldValueLength,
        int maxPdfBytes
    ) {}
    public record Rabbit(
        boolean enabled,
        String jobsExchange,
        String eventsExchange,
        String jobsQueue,
        String jobsDlq,
        String eventsQueue,
        String jobsRoutingKey,
        String jobsDlx
    ) {}
}
