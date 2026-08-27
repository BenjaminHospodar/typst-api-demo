package com.yourco.pdfgen;

import com.yourco.pdfgen.config.PdfGenProperties;
import io.github.resilience4j.bulkhead.BulkheadConfig;
import io.github.resilience4j.bulkhead.BulkheadRegistry;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import io.github.resilience4j.timelimiter.TimeLimiterRegistry;

import java.time.Duration;

public final class TestSupport {

    private TestSupport() {}

    public static PdfGenProperties properties() {
        return new PdfGenProperties(
                "test-key",
                new PdfGenProperties.Compiler("localhost", 50051, 5_000, 1_048_576),
                new PdfGenProperties.Queue(500),
                new PdfGenProperties.Limits(1_048_576, 200, 64, 8192, 20_971_520),
                new PdfGenProperties.Rabbit(
                        false,
                        "pdfgen.jobs",
                        "pdfgen.events",
                        "pdfgen.jobs.q",
                        "pdfgen.jobs.dlq",
                        "pdfgen.events.q",
                        "generate",
                        "pdfgen.jobs.dlx"
                )
        );
    }

    public static CircuitBreakerRegistry circuitBreakerRegistry() {
        return CircuitBreakerRegistry.of(CircuitBreakerConfig.custom()
                .slidingWindowSize(10)
                .minimumNumberOfCalls(5)
                .failureRateThreshold(50)
                .waitDurationInOpenState(Duration.ofSeconds(10))
                .build());
    }

    public static RetryRegistry retryRegistry() {
        return RetryRegistry.of(RetryConfig.custom()
                .maxAttempts(3)
                .waitDuration(Duration.ofMillis(10))
                .retryOnException(ex -> ex instanceof com.yourco.pdfgen.exception.ServiceUnavailableException sue
                        && sue.isRetryable())
                .build());
    }

    public static BulkheadRegistry bulkheadRegistry() {
        return BulkheadRegistry.of(BulkheadConfig.custom()
                .maxConcurrentCalls(8)
                .maxWaitDuration(Duration.ofMillis(50))
                .build());
    }

    public static TimeLimiterRegistry timeLimiterRegistry() {
        return TimeLimiterRegistry.of(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofSeconds(5))
                .cancelRunningFuture(true)
                .build());
    }
}
