package com.yourco.pdfgen.model;

import jakarta.persistence.*;
import java.util.UUID;
import java.time.Instant;

@Entity
@Table(name = "templates")
public class Template {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String form;

    @Column(nullable = false)
    private String version;

    @Column(name = "typ_source", nullable = false, columnDefinition = "TEXT")
    private String typSource;

    @Column(columnDefinition = "JSONB", nullable = false)
    private String schema = "{}";

    @Column(nullable = false)
    private Boolean active = true;

    @Column(name = "created_at")
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getForm() { return form; }
    public void setForm(String form) { this.form = form; }

    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }

    public String getTypSource() { return typSource; }
    public void setTypSource(String typSource) { this.typSource = typSource; }

    public String getSchema() { return schema; }
    public void setSchema(String schema) { this.schema = schema; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
