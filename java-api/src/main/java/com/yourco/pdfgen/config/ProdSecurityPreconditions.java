package com.yourco.pdfgen.config;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("prod")
public class ProdSecurityPreconditions {

    public ProdSecurityPreconditions(PdfGenProperties props) {
        if (props.apiKey() == null || props.apiKey().isBlank()) {
            throw new IllegalStateException("PDFGEN_API_KEY must be set when profile=prod");
        }
        if (props.rabbit() == null || !props.rabbit().enabled()) {
            throw new IllegalStateException("pdfgen.rabbit.enabled must be true when profile=prod");
        }
    }
}
