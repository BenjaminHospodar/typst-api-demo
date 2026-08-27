package com.yourco.pdfgen.exception;

public class ServiceUnavailableException extends RuntimeException {

    private final boolean retryable;

    public ServiceUnavailableException(String message) {
        this(message, true);
    }

    public ServiceUnavailableException(String message, boolean retryable) {
        super(message);
        this.retryable = retryable;
    }

    public ServiceUnavailableException(String message, Throwable cause) {
        this(message, cause, true);
    }

    public ServiceUnavailableException(String message, Throwable cause, boolean retryable) {
        super(message, cause);
        this.retryable = retryable;
    }

    public boolean isRetryable() {
        return retryable;
    }
}
