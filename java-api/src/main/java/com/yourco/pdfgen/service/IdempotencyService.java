package com.yourco.pdfgen.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;

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
        for (int i = 0; i < 8; i++) {
            String existing = redis.opsForValue().get(PREFIX + idempotencyKey);
            if (existing != null && !existing.isBlank()) {
                return existing;
            }
            LockSupport.parkNanos(TimeUnit.MILLISECONDS.toNanos(5));
        }
        throw new IllegalStateException("Idempotency key " + idempotencyKey + " was claimed but has no job id");
    }

    public void release(String idempotencyKey, String jobId) {
        String existing = redis.opsForValue().get(PREFIX + idempotencyKey);
        if (jobId.equals(existing)) {
            redis.delete(PREFIX + idempotencyKey);
        }
    }
}
