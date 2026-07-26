package com.yourco.pdfgen.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "jobs")
public class Job {

    @Id
    private String id;

    @Column(nullable = false)
    private String form;

    @Column(nullable = false)
    private String version;

    @Column(nullable = false)
    private String status;

    @Column(name = "queued_at")
    private Instant queuedAt;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "finished_at")
    private Instant finishedAt;

    @Column(name = "error_msg")
    private String errorMsg;

    @Column(name = "page_count")
    private Integer pageCount;

    @Column(name = "compile_ms")
    private Integer compileMs;

    @PrePersist
    void prePersist() {
        if (queuedAt == null) queuedAt = Instant.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getForm() { return form; }
    public void setForm(String form) { this.form = form; }

    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getQueuedAt() { return queuedAt; }
    public void setQueuedAt(Instant queuedAt) { this.queuedAt = queuedAt; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getFinishedAt() { return finishedAt; }
    public void setFinishedAt(Instant finishedAt) { this.finishedAt = finishedAt; }

    public String getErrorMsg() { return errorMsg; }
    public void setErrorMsg(String errorMsg) { this.errorMsg = errorMsg; }

    public Integer getPageCount() { return pageCount; }
    public void setPageCount(Integer pageCount) { this.pageCount = pageCount; }

    public Integer getCompileMs() { return compileMs; }
    public void setCompileMs(Integer compileMs) { this.compileMs = compileMs; }
}
