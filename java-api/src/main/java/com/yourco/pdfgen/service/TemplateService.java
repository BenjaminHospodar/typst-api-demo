package com.yourco.pdfgen.service;

import com.yourco.pdfgen.exception.TemplateNotFoundException;
import com.yourco.pdfgen.model.Template;
import com.yourco.pdfgen.repository.TemplateRepository;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class TemplateService {

    public record CachedTemplate(String typSource, String schema) {}

    private final TemplateRepository db;

    public TemplateService(TemplateRepository db) {
        this.db = db;
    }

    @Cacheable(value = "templates", key = "#form + ':' + #version")
    public CachedTemplate getTemplate(String form, String version) {
        Template t = db.findByFormAndVersionAndActive(form, version, true)
                .orElseThrow(() -> new TemplateNotFoundException(form, version));
        String schema = t.getSchema() == null || t.getSchema().isBlank() ? "{}" : t.getSchema();
        return new CachedTemplate(t.getTypSource(), schema);
    }

    public String getTypSource(String form, String version) {
        return getTemplate(form, version).typSource();
    }
}
