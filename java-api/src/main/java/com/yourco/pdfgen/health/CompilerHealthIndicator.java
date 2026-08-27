package com.yourco.pdfgen.health;

import com.yourco.pdfgen.service.CompilerService;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class CompilerHealthIndicator implements HealthIndicator {

    private final CompilerService compilerService;

    public CompilerHealthIndicator(CompilerService compilerService) {
        this.compilerService = compilerService;
    }

    @Override
    public Health health() {
        if (compilerService.isHealthy()) {
            return Health.up().withDetail("compiler", "gRPC sidecar reachable").build();
        }
        return Health.down().withDetail("compiler", "gRPC sidecar unreachable").build();
    }
}
