package com.yourco.pdfgen.repository;

import com.yourco.pdfgen.model.Template;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TemplateRepository extends JpaRepository<Template, UUID> {
    Optional<Template> findByFormAndVersionAndActive(String form, String version, Boolean active);
}
