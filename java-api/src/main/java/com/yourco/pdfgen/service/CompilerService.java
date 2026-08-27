package com.yourco.pdfgen.service;

import com.yourco.pdfgen.config.PdfGenProperties;
import com.yourco.pdfgen.exception.CompileException;
import com.yourco.pdfgen.exception.PayloadTooLargeException;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.grpc.CompileRequest;
import com.yourco.pdfgen.grpc.CompileResponse;
import com.yourco.pdfgen.grpc.CompileServiceGrpc;
import com.yourco.pdfgen.grpc.HealthRequest;
import com.yourco.pdfgen.grpc.HealthResponse;
import io.github.resilience4j.bulkhead.Bulkhead;
import io.github.resilience4j.bulkhead.BulkheadFullException;
import io.github.resilience4j.bulkhead.BulkheadRegistry;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import io.github.resilience4j.timelimiter.TimeLimiter;
import io.github.resilience4j.timelimiter.TimeLimiterRegistry;
import io.grpc.ManagedChannel;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Supplier;

@Service
public class CompilerService {

    static final String RESILIENCE_NAME = "compiler";

    private final ManagedChannel channel;
    private final PdfGenProperties.Compiler compilerProps;
    private final CircuitBreaker circuitBreaker;
    private final Retry retry;
    private final Bulkhead bulkhead;
    private final TimeLimiter timeLimiter;

    public CompilerService(ManagedChannel channel,
                           PdfGenProperties props,
                           CircuitBreakerRegistry circuitBreakerRegistry,
                           RetryRegistry retryRegistry,
                           BulkheadRegistry bulkheadRegistry,
                           TimeLimiterRegistry timeLimiterRegistry) {
        this.channel = channel;
        this.compilerProps = props.compiler();
        this.circuitBreaker = circuitBreakerRegistry.circuitBreaker(RESILIENCE_NAME);
        this.bulkhead = bulkheadRegistry.bulkhead(RESILIENCE_NAME);
        this.retry = Retry.of(RESILIENCE_NAME, RetryConfig.from(
                        retryRegistry.getConfiguration(RESILIENCE_NAME).orElse(retryRegistry.getDefaultConfig()))
                .retryOnException(ex -> ex instanceof ServiceUnavailableException sue && sue.isRetryable())
                .ignoreExceptions(CompileException.class, PayloadTooLargeException.class)
                .waitDuration(Duration.ofMillis(200))
                .maxAttempts(3)
                .build());
        this.timeLimiter = timeLimiterRegistry.timeLimiter(RESILIENCE_NAME);
    }

    public CompileResult compile(String jobId, String templateSource, String inputsJson) {
        Supplier<CompileResult> decorated = Retry.decorateSupplier(retry,
                CircuitBreaker.decorateSupplier(circuitBreaker,
                        Bulkhead.decorateSupplier(bulkhead,
                                () -> doCompile(jobId, templateSource, inputsJson))));

        try {
            return timeLimiter.executeFutureSupplier(
                    () -> java.util.concurrent.CompletableFuture.supplyAsync(decorated));
        } catch (CallNotPermittedException e) {
            throw new ServiceUnavailableException("Compiler circuit breaker is open", e, true);
        } catch (BulkheadFullException e) {
            throw new ServiceUnavailableException("Compiler bulkhead is full", e, true);
        } catch (TimeoutException e) {
            throw new ServiceUnavailableException("Compiler timed out", e, false);
        } catch (Exception e) {
            throw unwrap(e);
        }
    }

    public boolean isHealthy() {
        try {
            CompileServiceGrpc.CompileServiceBlockingStub stub = CompileServiceGrpc
                    .newBlockingStub(channel)
                    .withDeadlineAfter(1, TimeUnit.SECONDS);
            HealthResponse response = stub.health(HealthRequest.newBuilder().build());
            return response.getOk();
        } catch (Exception e) {
            return false;
        }
    }

    private CompileResult doCompile(String jobId, String templateSource, String inputsJson) {
        CompileServiceGrpc.CompileServiceBlockingStub stub = CompileServiceGrpc
                .newBlockingStub(channel)
                .withDeadlineAfter(compilerProps.deadlineMs(), TimeUnit.MILLISECONDS)
                .withMaxInboundMessageSize(compilerProps.maxMessageSize());

        CompileRequest request = CompileRequest.newBuilder()
                .setJobId(jobId)
                .setTemplateSource(templateSource)
                .setInputsJson(inputsJson)
                .build();

        try {
            CompileResponse response = stub.compile(request);
            if (!response.getError().isBlank()) {
                throw new CompileException(response.getError());
            }
            return new CompileResult(
                    response.getPdfBytes().toByteArray(),
                    response.getPages(),
                    response.getCompileMs(),
                    response.getError()
            );
        } catch (StatusRuntimeException e) {
            Status.Code code = e.getStatus().getCode();
            if (code == Status.Code.UNAVAILABLE || code == Status.Code.RESOURCE_EXHAUSTED) {
                throw new ServiceUnavailableException("Compiler sidecar unavailable: " + e.getStatus(), e, true);
            }
            if (code == Status.Code.DEADLINE_EXCEEDED) {
                throw new ServiceUnavailableException("Compiler sidecar deadline exceeded: " + e.getStatus(), e, false);
            }
            throw new CompileException("Compiler call failed: " + e.getStatus(), e);
        }
    }

    private static RuntimeException unwrap(Throwable e) {
        Throwable current = e;
        while (current != null
                && (current instanceof CompletionException || current instanceof ExecutionException)
                && current.getCause() != null) {
            current = current.getCause();
        }
        if (current instanceof RuntimeException runtime) {
            return runtime;
        }
        if (current instanceof TimeoutException timeout) {
            return new ServiceUnavailableException("Compiler timed out", timeout, false);
        }
        return new CompileException(current == null ? "Compiler call failed" : current.getMessage(), current);
    }
}
