// tests/integration/OrderUserIntegrationTest.java
package com.selimhorri.app.integration;

import com.selimhorri.app.business.order.model.dto.OrderDto;
import com.selimhorri.app.business.user.model.dto.UserDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("integration")
class OrderUserIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testCreateOrderForUser_ShouldLinkUserAndOrder() {
        // Given - Create user first
        UserDto userDto = new UserDto();
        userDto.setUsername("orderuser");
        userDto.setEmail("orderuser@test.com");
        
        ResponseEntity<UserDto> userResponse = restTemplate.postForEntity(
            createURLWithPort("/api/users"), userDto, UserDto.class);
        
        UserDto createdUser = userResponse.getBody();

        // Given - Create order for user
        OrderDto orderDto = new OrderDto();
        orderDto.setUserId(createdUser.getId());
        orderDto.setDescription("Integration test order");

        // When
        ResponseEntity<OrderDto> orderResponse = restTemplate.postForEntity(
            createURLWithPort("/api/orders"),
            orderDto,
            OrderDto.class
        );

        // Then
        assertEquals(HttpStatus.CREATED, orderResponse.getStatusCode());
        assertNotNull(orderResponse.getBody());
        assertNotNull(orderResponse.getBody().getId());
        assertEquals(createdUser.getId(), orderResponse.getBody().getUserId());
        assertEquals("Integration test order", orderResponse.getBody().getDescription());
    }

    @Test
    void testGetUserOrders_ShouldReturnOrdersForUser() {
        // Given - Create user and order
        UserDto userDto = new UserDto();
        userDto.setUsername("orderlistuser");
        userDto.setEmail("orderlistuser@test.com");
        
        ResponseEntity<UserDto> userResponse = restTemplate.postForEntity(
            createURLWithPort("/api/users"), userDto, UserDto.class);
        
        UserDto createdUser = userResponse.getBody();

        OrderDto orderDto = new OrderDto();
        orderDto.setUserId(createdUser.getId());
        orderDto.setDescription("Test order for list");

        restTemplate.postForEntity(
            createURLWithPort("/api/orders"), orderDto, OrderDto.class);

        // When
        ResponseEntity<OrderDto[]> response = restTemplate.getForEntity(
            createURLWithPort("/api/users/" + createdUser.getId() + "/orders"),
            OrderDto[].class
        );

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().length >= 1);
        assertEquals(createdUser.getId(), response.getBody()[0].getUserId());
    }
}