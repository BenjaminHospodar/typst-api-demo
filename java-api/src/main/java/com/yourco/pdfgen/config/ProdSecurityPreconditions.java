package com.yourco.pdfgen.config;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("prod")
public class ProdSecurityPreconditions {

    public ProdSecurityPreconditions(PdfGenProperties props) {
        String apiKey = props.apiKey();
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("PDFGEN_API_KEY must be set when profile=prod");
        }
        if (isPlaceholder(apiKey)) {
            throw new IllegalStateException("PDFGEN_API_KEY must not use a placeholder value in prod");
        }
        if (props.rabbit() == null || !props.rabbit().enabled()) {
            throw new IllegalStateException("pdfgen.rabbit.enabled must be true when profile=prod");
        }
    }

    private static boolean isPlaceholder(String apiKey) {
        return "changeme".equalsIgnoreCase(apiKey)
                || "changeme-set-a-real-key".equalsIgnoreCase(apiKey)
                || "local-dev-key".equalsIgnoreCase(apiKey);
    }
}
