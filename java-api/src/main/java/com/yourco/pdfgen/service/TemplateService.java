package com.yourco.pdfgen.service;

import com.yourco.pdfgen.exception.TemplateNotFoundException;
import com.yourco.pdfgen.model.Template;
import com.yourco.pdfgen.repository.TemplateRepository;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

@Service
public class TemplateService {

    private final StringRedisTemplate redis;
    private final TemplateRepository db;

    public TemplateService(StringRedisTemplate redis, TemplateRepository db) {
        this.redis = redis;
        this.db = db;
    }

    /**
     * Resolve template source with Redis caching.
     * 1. Check Redis cache
     * 2. On miss: load from Postgres, write to Redis (no TTL — templates are config)
     */
    public String getTypSource(String form, String version) {
        String key = "template:" + form + ":" + version;

        String cached = redis.opsForValue().get(key);
        if (cached != null) return cached;

        Template t = db.findByFormAndVersionAndActive(form, version, true)
                .orElseThrow(() -> new TemplateNotFoundException(form, version));

        redis.opsForValue().set(key, t.getTypSource());
        return t.getTypSource();
    }

    /**
     * Invalidate Redis cache when a template is updated.
     */
    public void invalidateCache(String form, String version) {
        String key = "template:" + form + ":" + version;
        redis.delete(key);
    }
}
