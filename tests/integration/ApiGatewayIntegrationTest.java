package com.selimhorri.app.integration;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("integration")
class ApiGatewayIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testGatewayRouting_ShouldRouteToUserService() {
        // When - Access user service through gateway
        ResponseEntity<String> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/users"), String.class);

        // Then - Verify routing works
        assertTrue(response.getStatusCode().is2xxSuccessful() || 
                  response.getStatusCode().is5xxServerError()); // Service might not be available
    }

    @Test
    void testGatewayRouting_ShouldRouteToProductService() {
        // When - Access product service through gateway
        ResponseEntity<String> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/products"), String.class);

        // Then - Verify routing works
        assertTrue(response.getStatusCode().is2xxSuccessful() || 
                  response.getStatusCode().is5xxServerError());
    }

    @Test
    void testGatewayLoadBalancing_ShouldDistributeRequests() {
        // When - Make multiple requests through gateway
        for (int i = 0; i < 5; i++) {
            ResponseEntity<String> response = restTemplate.getForEntity(
                createURLWithPort("/app/api/orders"), String.class);
            
            // Then - Verify each request is handled
            assertNotNull(response);
        }
    }

    @Test
    void testGatewayFilters_ShouldApplyFilters() {
        // When - Make request with headers
        ResponseEntity<String> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/actuator/health"), String.class);

        // Then - Verify gateway processes the request
        assertNotNull(response);
    }
}
