package com.yourco.pdfgen.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.yourco.pdfgen.TestSupport;
import com.yourco.pdfgen.exception.InvalidRequestException;
import com.yourco.pdfgen.exception.PayloadTooLargeException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class FieldValidatorTest {

    private FieldValidator validator;

    @BeforeEach
    void setUp() {
        validator = new FieldValidator(TestSupport.properties(), new ObjectMapper());
    }

    @Test
    void acceptsIdentifierKeys() {
        assertDoesNotThrow(() -> validator.validateFields(Map.of("customer_name", "Acme")));
    }

    @Test
    void rejectsInvalidKeys() {
        assertThrows(InvalidRequestException.class,
                () -> validator.validateFields(Map.of("customer-name", "Acme")));
    }

    @Test
    void rejectsTooManyFields() {
        Map<String, String> fields = new HashMap<>();
        for (int i = 0; i < 201; i++) {
            fields.put("k" + i, "v");
        }
        assertThrows(PayloadTooLargeException.class, () -> validator.validateFields(fields));
    }

    @Test
    void rejectsOversizedTemplate() {
        String huge = "x".repeat(1_048_577);
        assertThrows(PayloadTooLargeException.class, () -> validator.validateTemplate(huge));
    }

    @Test
    void rejectsOversizedPdf() {
        assertThrows(PayloadTooLargeException.class, () -> validator.validatePdf(new byte[20_971_521]));
    }

    @Test
    void schemaRequiresListedFields() {
        String schema = "{\"required\":[\"name\",\"date\"]}";
        assertThrows(InvalidRequestException.class,
                () -> validator.validateAgainstSchema(schema, Map.of("name", "Acme")));
        assertDoesNotThrow(() -> validator.validateAgainstSchema(schema, Map.of("name", "Acme", "date", "2024-01-01")));
    }
}
