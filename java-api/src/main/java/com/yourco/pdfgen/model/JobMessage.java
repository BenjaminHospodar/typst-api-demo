package com.yourco.pdfgen.model;

import java.util.Map;

public record JobMessage(
    String jobId,
    String form,
    String version,
    Map<String, String> fields
) {}
