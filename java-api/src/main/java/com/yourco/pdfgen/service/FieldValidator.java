package com.yourco.pdfgen.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yourco.pdfgen.config.PdfGenProperties;
import com.yourco.pdfgen.exception.InvalidRequestException;
import com.yourco.pdfgen.exception.PayloadTooLargeException;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.regex.Pattern;

@Component
public class FieldValidator {

    private static final Pattern IDENTIFIER = Pattern.compile("^[a-zA-Z_][a-zA-Z0-9_]*$");

    private final PdfGenProperties.Limits limits;
    private final ObjectMapper objectMapper;

    public FieldValidator(PdfGenProperties props, ObjectMapper objectMapper) {
        this.limits = props.limits();
        this.objectMapper = objectMapper;
    }

    public void validateTemplate(String typSource) {
        if (typSource != null && typSource.getBytes(StandardCharsets.UTF_8).length > limits.maxTemplateBytes()) {
            throw new PayloadTooLargeException("Template exceeds max size of " + limits.maxTemplateBytes() + " bytes");
        }
    }

    public void validateFields(Map<String, String> fields) {
        if (fields.size() > limits.maxFieldCount()) {
            throw new PayloadTooLargeException("Too many fields (max " + limits.maxFieldCount() + ")");
        }
        long payload = 0;
        for (Map.Entry<String, String> entry : fields.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();
            if (key == null || key.length() > limits.maxFieldKeyLength() || !IDENTIFIER.matcher(key).matches()) {
                throw new InvalidRequestException("Invalid field key: " + key);
            }
            if (value != null && value.length() > limits.maxFieldValueLength()) {
                throw new PayloadTooLargeException("Field value too long for key: " + key);
            }
            payload += key.length() + (value == null ? 0 : value.length());
        }
        if (payload > limits.maxTemplateBytes()) {
            throw new PayloadTooLargeException("Field payload exceeds max size of " + limits.maxTemplateBytes() + " bytes");
        }
    }

    public void validateAgainstSchema(String schemaJson, Map<String, String> fields) {
        if (schemaJson == null || schemaJson.isBlank() || "{}".equals(schemaJson.strip())) {
            return;
        }
        JsonNode schema;
        try {
            schema = objectMapper.readTree(schemaJson);
        } catch (JsonProcessingException e) {
            throw new InvalidRequestException("Template schema is not valid JSON");
        }
        JsonNode required = schema.get("required");
        if (required == null || !required.isArray()) {
            return;
        }
        for (JsonNode keyNode : required) {
            String key = keyNode.asText();
            String value = fields.get(key);
            if (value == null || value.isBlank()) {
                throw new InvalidRequestException("Missing required field: " + key);
            }
        }
    }

    public void validatePdf(byte[] pdf) {
        if (pdf != null && pdf.length > limits.maxPdfBytes()) {
            throw new PayloadTooLargeException("PDF exceeds max size of " + limits.maxPdfBytes() + " bytes");
        }
    }
}
