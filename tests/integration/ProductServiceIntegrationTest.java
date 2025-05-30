// tests/integration/ProductServiceIntegrationTest.java
package com.selimhorri.app.integration;

import com.selimhorri.app.business.product.model.dto.ProductDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("integration")
class ProductServiceIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testGetAllProducts_ShouldReturnProductList() {
        // When
        ResponseEntity<ProductDto[]> response = restTemplate.getForEntity(
            createURLWithPort("/api/products"),
            ProductDto[].class
        );

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }

    @Test
    void testCreateProduct_ShouldReturnCreatedProduct_WhenValidData() {
        // Given
        ProductDto productDto = new ProductDto();
        productDto.setName("Integration Test Product");
        productDto.setDescription("Product for integration testing");
        productDto.setPrice(BigDecimal.valueOf(99.99));
        productDto.setStock(10);

        // When
        ResponseEntity<ProductDto> response = restTemplate.postForEntity(
            createURLWithPort("/api/products"),
            productDto,
            ProductDto.class
        );

        // Then
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertNotNull(response.getBody().getId());
        assertEquals("Integration Test Product", response.getBody().getName());
        assertEquals(BigDecimal.valueOf(99.99), response.getBody().getPrice());
    }

    @Test
    void testSearchProducts_ShouldReturnMatchingProducts_WhenSearchTermProvided() {
        // When
        ResponseEntity<ProductDto[]> response = restTemplate.getForEntity(
            createURLWithPort("/api/products/search?q=laptop"),
            ProductDto[].class
        );

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }
}