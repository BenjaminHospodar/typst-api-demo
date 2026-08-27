package com.yourco.pdfgen.service;

import com.google.protobuf.ByteString;
import com.yourco.pdfgen.TestSupport;
import com.yourco.pdfgen.exception.CompileException;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.grpc.CompileRequest;
import com.yourco.pdfgen.grpc.CompileResponse;
import com.yourco.pdfgen.grpc.CompileServiceGrpc;
import com.yourco.pdfgen.grpc.HealthRequest;
import com.yourco.pdfgen.grpc.HealthResponse;
import io.grpc.ManagedChannel;
import io.grpc.Server;
import io.grpc.Status;
import io.grpc.netty.shaded.io.grpc.netty.NettyChannelBuilder;
import io.grpc.netty.shaded.io.grpc.netty.NettyServerBuilder;
import io.grpc.stub.StreamObserver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CompilerServiceResilienceTest {

    private Server server;
    private ManagedChannel channel;
    private FakeCompileService fake;
    private CompilerService compilerService;

    @BeforeEach
    void setUp() throws IOException {
        fake = new FakeCompileService();
        server = NettyServerBuilder.forPort(0)
                .directExecutor()
                .addService(fake)
                .build()
                .start();
        channel = NettyChannelBuilder.forAddress("localhost", server.getPort())
                .usePlaintext()
                .build();
        compilerService = new CompilerService(
                channel,
                TestSupport.properties(),
                TestSupport.circuitBreakerRegistry(),
                TestSupport.retryRegistry(),
                TestSupport.bulkheadRegistry(),
                TestSupport.timeLimiterRegistry()
        );
    }

    @AfterEach
    void tearDown() {
        if (channel != null) {
            channel.shutdownNow();
        }
        if (server != null) {
            server.shutdownNow();
        }
    }

    @Test
    void compileReturnsPdf() {
        CompileResult result = compilerService.compile("job-1", "#ok", "{}");
        assertArrayEquals("%PDF-fake".getBytes(), result.pdfBytes());
        assertEquals(1, result.pages());
        assertEquals(1, fake.calls.get());
    }

    @Test
    void compileErrorIsNotRetried() {
        fake.error = "typst error: boom";
        CompileException ex = assertThrows(CompileException.class,
                () -> compilerService.compile("job-1", "#bad", "{}"));
        assertTrue(ex.getMessage().contains("boom"));
        assertEquals(1, fake.calls.get());
    }

    @Test
    void unavailableIsRetriedThenSucceeds() {
        fake.failTimes = 2;
        fake.failStatus = Status.UNAVAILABLE;
        CompileResult result = compilerService.compile("job-1", "#ok", "{}");
        assertArrayEquals("%PDF-fake".getBytes(), result.pdfBytes());
        assertEquals(3, fake.calls.get());
    }

    @Test
    void deadlineExceededIsNotRetried() {
        fake.failTimes = 5;
        fake.failStatus = Status.DEADLINE_EXCEEDED;
        ServiceUnavailableException ex = assertThrows(ServiceUnavailableException.class,
                () -> compilerService.compile("job-1", "#ok", "{}"));
        assertTrue(!ex.isRetryable());
        assertEquals(1, fake.calls.get());
    }

    @Test
    void healthUsesSidecar() {
        assertTrue(compilerService.isHealthy());
    }

    static final class FakeCompileService extends CompileServiceGrpc.CompileServiceImplBase {
        final AtomicInteger calls = new AtomicInteger();
        volatile int failTimes;
        volatile Status failStatus;
        volatile String error;

        @Override
        public void compile(CompileRequest request, StreamObserver<CompileResponse> responseObserver) {
            int n = calls.incrementAndGet();
            if (failStatus != null && n <= failTimes) {
                responseObserver.onError(failStatus.asRuntimeException());
                return;
            }
            if (error != null) {
                responseObserver.onNext(CompileResponse.newBuilder().setError(error).build());
                responseObserver.onCompleted();
                return;
            }
            responseObserver.onNext(CompileResponse.newBuilder()
                    .setJobId(request.getJobId())
                    .setPdfBytes(ByteString.copyFromUtf8("%PDF-fake"))
                    .setPages(1)
                    .setCompileMs(4)
                    .build());
            responseObserver.onCompleted();
        }

        @Override
        public void health(HealthRequest request, StreamObserver<HealthResponse> responseObserver) {
            responseObserver.onNext(HealthResponse.newBuilder().setOk(true).setTypstVersion("0.12").build());
            responseObserver.onCompleted();
        }
    }
}
