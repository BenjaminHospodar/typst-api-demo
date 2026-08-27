package com.yourco.pdfgen.config;

import com.yourco.pdfgen.TestSupport;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ApiKeyAuthFilterTest {

    @Test
    void rejectsMissingKeyWhenConfigured() throws ServletException, IOException {
        ApiKeyAuthFilter filter = new ApiKeyAuthFilter(TestSupport.properties());
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/generate");
        request.setRequestURI("/api/v1/generate");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertEquals(401, response.getStatus());
    }

    @Test
    void allowsMatchingKey() throws ServletException, IOException {
        ApiKeyAuthFilter filter = new ApiKeyAuthFilter(TestSupport.properties());
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/generate");
        request.setRequestURI("/api/v1/generate");
        request.addHeader("X-API-Key", "test-key");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertEquals(200, response.getStatus());
    }

    @Test
    void healthIsExempt() throws ServletException, IOException {
        ApiKeyAuthFilter filter = new ApiKeyAuthFilter(TestSupport.properties());
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/actuator/health/readiness");
        request.setRequestURI("/actuator/health/readiness");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertEquals(200, response.getStatus());
    }
}
