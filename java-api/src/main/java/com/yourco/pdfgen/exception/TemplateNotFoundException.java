package com.yourco.pdfgen.exception;

public class TemplateNotFoundException extends RuntimeException {
    public TemplateNotFoundException(String form, String version) {
        super("Template not found: form=" + form + ", version=" + version);
    }
}
