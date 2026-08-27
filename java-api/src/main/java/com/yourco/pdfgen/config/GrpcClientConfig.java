package com.yourco.pdfgen.config;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import jakarta.annotation.PreDestroy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GrpcClientConfig {

    private ManagedChannel channel;

    @Bean
    public ManagedChannel compilerChannel(PdfGenProperties props) {
        PdfGenProperties.Compiler compiler = props.compiler();
        channel = ManagedChannelBuilder
                .forAddress(compiler.host(), compiler.port())
                .usePlaintext()
                .maxInboundMessageSize(compiler.maxMessageSize())
                .build();
        return channel;
    }

    @PreDestroy
    public void shutdown() {
        if (channel != null) {
            channel.shutdown();
        }
    }
}
