package com.yourco.pdfgen.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class IdempotencyServiceTest {

    @Mock
    StringRedisTemplate redis;
    @Mock
    ValueOperations<String, String> values;

    IdempotencyService service;

    @BeforeEach
    void setUp() {
        when(redis.opsForValue()).thenReturn(values);
        service = new IdempotencyService(redis);
    }

    @Test
    void claimStoresFirstJobId() {
        when(values.setIfAbsent(eq("pdf:idempotency:abc"), eq("job-1"), any(Duration.class)))
                .thenReturn(true);

        assertEquals("job-1", service.claim("abc", "job-1"));
        verify(values).setIfAbsent(eq("pdf:idempotency:abc"), eq("job-1"), any(Duration.class));
    }

    @Test
    void claimReturnsExistingJobIdOnReplay() {
        when(values.setIfAbsent(eq("pdf:idempotency:abc"), eq("job-2"), any(Duration.class)))
                .thenReturn(false);
        when(values.get("pdf:idempotency:abc")).thenReturn("job-1");

        assertEquals("job-1", service.claim("abc", "job-2"));
    }

    @Test
    void claimDoesNotInventAJobIdWhenValueIsMissing() {
        when(values.setIfAbsent(eq("pdf:idempotency:abc"), eq("job-2"), any(Duration.class)))
                .thenReturn(false);
        when(values.get("pdf:idempotency:abc")).thenReturn(null);

        assertThrows(IllegalStateException.class, () -> service.claim("abc", "job-2"));
    }
}
