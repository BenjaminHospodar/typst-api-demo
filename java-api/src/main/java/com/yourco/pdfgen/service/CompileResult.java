package com.yourco.pdfgen.service;

public record CompileResult(byte[] pdfBytes, int pages, int compileMs, String error) {
    public boolean isSuccess() {
        return error == null || error.isBlank();
    }
}
