package com.yourco.pdfgen.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yourco.pdfgen.exception.CompileException;
import com.yourco.pdfgen.exception.ServiceUnavailableException;
import com.yourco.pdfgen.model.DomainEvent;
import com.yourco.pdfgen.model.Job;
import com.yourco.pdfgen.model.JobMessage;
import com.yourco.pdfgen.repository.JobRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JobServiceTest {

    @Mock StringRedisTemplate redis;
    @Mock ValueOperations<String, String> values;
    @Mock ObjectMapper objectMapper;
    @Mock JobRepository jobRepository;
    @Mock CompilerService compilerService;
    @Mock TemplateService templateService;
    @Mock FieldValidator fieldValidator;
    @Mock EventPublisher eventPublisher;

    JobService jobService;
    Job job;

    @BeforeEach
    void setUp() {
        when(redis.opsForValue()).thenReturn(values);
        jobService = new JobService(
                redis, objectMapper, jobRepository, compilerService,
                templateService, fieldValidator, eventPublisher
        );
        job = new Job();
        job.setId("job-1");
        job.setForm("invoice");
        job.setVersion("2.0.0");
        job.setStatus("pending");
        when(jobRepository.findById("job-1")).thenReturn(Optional.of(job));
        when(jobRepository.save(any(Job.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void createJobWritesPendingAndPublishesQueued() {
        jobService.createJob("job-1", "invoice", "2.0.0", Map.of("name", "Acme"));

        ArgumentCaptor<Job> saved = ArgumentCaptor.forClass(Job.class);
        verify(jobRepository).save(saved.capture());
        assertEquals("pending", saved.getValue().getStatus());
        ArgumentCaptor<DomainEvent> event = ArgumentCaptor.forClass(DomainEvent.class);
        verify(eventPublisher).publish(event.capture());
        assertEquals("job.queued", event.getValue().type());
        assertEquals("job-1", event.getValue().jobId());
    }

    @Test
    void compileAndStoreMarksDoneAndPublishesCompiled() throws JsonProcessingException {
        when(templateService.getTemplate("invoice", "2.0.0"))
                .thenReturn(new TemplateService.CachedTemplate("#set page(paper: \"a4\")", "{}"));
        when(objectMapper.writeValueAsString(any())).thenReturn("{\"name\":\"Acme\"}");
        when(compilerService.compile(eq("job-1"), any(), any()))
                .thenReturn(new CompileResult("%PDF".getBytes(), 1, 12, ""));
        when(redis.execute(any(RedisCallback.class), anyBoolean())).thenReturn(null);

        byte[] pdf = jobService.compileAndStore("job-1", "invoice", "2.0.0", Map.of("name", "Acme"));

        assertArrayEquals("%PDF".getBytes(), pdf);
        assertEquals("done", job.getStatus());
        assertEquals(12, job.getCompileMs());
        ArgumentCaptor<DomainEvent> event = ArgumentCaptor.forClass(DomainEvent.class);
        verify(eventPublisher).publish(event.capture());
        assertEquals("job.compiled", event.getValue().type());
        assertEquals(12, event.getValue().compileMs());
    }

    @Test
    void compileAndStoreMarksErrorAndPublishesFailed() throws JsonProcessingException {
        when(templateService.getTemplate("invoice", "2.0.0"))
                .thenReturn(new TemplateService.CachedTemplate("#oops", "{}"));
        when(objectMapper.writeValueAsString(any())).thenReturn("{}");
        when(compilerService.compile(eq("job-1"), any(), any()))
                .thenThrow(new CompileException("typst error"));

        assertThrows(CompileException.class,
                () -> jobService.compileAndStore("job-1", "invoice", "2.0.0", Map.of()));

        assertEquals("error", job.getStatus());
        ArgumentCaptor<DomainEvent> event = ArgumentCaptor.forClass(DomainEvent.class);
        verify(eventPublisher).publish(event.capture());
        assertEquals("job.failed", event.getValue().type());
    }
}

@ExtendWith(MockitoExtension.class)
class JobWorkerTest {

    @Mock JobService jobService;
    JobWorker worker;

    @BeforeEach
    void setUp() {
        worker = new JobWorker(jobService);
    }

    @Test
    void poisonCompileIsNotRethrown() {
        JobMessage message = new JobMessage("job-1", "invoice", "2.0.0", Map.of());
        doThrow(new CompileException("bad template"))
                .when(jobService).compileAndStore("job-1", "invoice", "2.0.0", Map.of());

        worker.processJob(message);
        verify(jobService).compileAndStore("job-1", "invoice", "2.0.0", Map.of());
    }

    @Test
    void retryableUnavailableIsRethrownForDlq() {
        JobMessage message = new JobMessage("job-1", "invoice", "2.0.0", Map.of());
        doThrow(new ServiceUnavailableException("sidecar down", true))
                .when(jobService).compileAndStore("job-1", "invoice", "2.0.0", Map.of());

        assertThrows(ServiceUnavailableException.class, () -> worker.processJob(message));
    }

    @Test
    void nonRetryableUnavailableIsAcked() {
        JobMessage message = new JobMessage("job-1", "invoice", "2.0.0", Map.of());
        doThrow(new ServiceUnavailableException("deadline", false))
                .when(jobService).compileAndStore("job-1", "invoice", "2.0.0", Map.of());

        worker.processJob(message);
        verify(jobService).compileAndStore(any(), any(), any(), any());
    }
}
