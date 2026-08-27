package com.yourco.pdfgen.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Service
public class IdempotencyService {

    private static final String PREFIX = "pdf:idempotency:";
    private static final Duration TTL = Duration.ofHours(24);

    private final StringRedisTemplate redis;

    public IdempotencyService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /**
     * Atomically claims {@code jobId} for the key. Returns {@code jobId} if this
     * caller owns the request, or the previously stored job id if the key was replayed.
     */
    public String claim(String idempotencyKey, String jobId) {
        Boolean claimed = redis.opsForValue().setIfAbsent(PREFIX + idempotencyKey, jobId, TTL);
        if (Boolean.TRUE.equals(claimed)) {
            return jobId;
        }
        String existing = redis.opsForValue().get(PREFIX + idempotencyKey);
        return existing != null ? existing : jobId;
    }

    public String findJobId(String idempotencyKey) {
        return redis.opsForValue().get(PREFIX + idempotencyKey);
    }
}
