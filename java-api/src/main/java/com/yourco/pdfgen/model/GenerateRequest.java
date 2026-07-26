package com.yourco.pdfgen.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.Map;

public record GenerateRequest(
    @NotBlank String form,
    @NotBlank String version,
    @NotNull  Map<String, String> fields
) {}
