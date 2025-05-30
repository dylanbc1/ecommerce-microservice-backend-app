// tests/integration/UserServiceIntegrationTest.java
package com.selimhorri.app.integration;

import com.selimhorri.app.business.user.model.dto.UserDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestMethodOrder;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("integration")
@TestMethodOrder(OrderAnnotation.class)
class UserServiceIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    @Order(1)
    void testCreateUser_ShouldReturnCreatedUser_WhenValidDataProvided() {
        // Given
        UserDto userDto = new UserDto();
        userDto.setUsername("integrationtest");
        userDto.setEmail("integration@test.com");
        userDto.setFirstName("Integration");
        userDto.setLastName("Test");

        // When
        ResponseEntity<UserDto> response = restTemplate.postForEntity(
            createURLWithPort("/api/users"), 
            userDto, 
            UserDto.class
        );

        // Then
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertNotNull(response.getBody().getId());
        assertEquals("integrationtest", response.getBody().getUsername());
        assertEquals("integration@test.com", response.getBody().getEmail());
    }

    @Test
    @Order(2)
    void testGetUser_ShouldReturnUser_WhenUserExists() {
        // Given - Create user first
        UserDto userDto = new UserDto();
        userDto.setUsername("gettest");
        userDto.setEmail("gettest@test.com");
        
        ResponseEntity<UserDto> createResponse = restTemplate.postForEntity(
            createURLWithPort("/api/users"), userDto, UserDto.class);
        
        Long userId = createResponse.getBody().getId();

        // When
        ResponseEntity<UserDto> response = restTemplate.getForEntity(
            createURLWithPort("/api/users/" + userId), 
            UserDto.class
        );

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(userId, response.getBody().getId());
        assertEquals("gettest", response.getBody().getUsername());
    }

    @Test
    @Order(3)
    void testGetAllUsers_ShouldReturnUserList() {
        // When
        ResponseEntity<UserDto[]> response = restTemplate.getForEntity(
            createURLWithPort("/api/users"), 
            UserDto[].class
        );

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().length >= 2); // At least 2 users from previous tests
    }

    @Test
    @Order(4)
    void testUpdateUser_ShouldReturnUpdatedUser_WhenValidData() {
        // Given - Create user first
        UserDto userDto = new UserDto();
        userDto.setUsername("updatetest");
        userDto.setEmail("updatetest@test.com");
        
        ResponseEntity<UserDto> createResponse = restTemplate.postForEntity(
            createURLWithPort("/api/users"), userDto, UserDto.class);
        
        UserDto createdUser = createResponse.getBody();
        createdUser.setFirstName("Updated");
        createdUser.setLastName("Name");

        // When
        restTemplate.put(createURLWithPort("/api/users"), createdUser);
        
        ResponseEntity<UserDto> getResponse = restTemplate.getForEntity(
            createURLWithPort("/api/users/" + createdUser.getId()), 
            UserDto.class
        );

        // Then
        assertEquals(HttpStatus.OK, getResponse.getStatusCode());
        assertEquals("Updated", getResponse.getBody().getFirstName());
        assertEquals("Name", getResponse.getBody().getLastName());
    }

    @Test
    @Order(5)
    void testDeleteUser_ShouldRemoveUser_WhenValidId() {
        // Given - Create user first
        UserDto userDto = new UserDto();
        userDto.setUsername("deletetest");
        userDto.setEmail("deletetest@test.com");
        
        ResponseEntity<UserDto> createResponse = restTemplate.postForEntity(
            createURLWithPort("/api/users"), userDto, UserDto.class);
        
        Long userId = createResponse.getBody().getId();

        // When
        restTemplate.delete(createURLWithPort("/api/users/" + userId));

        // Then - Verify user is deleted
        ResponseEntity<UserDto> getResponse = restTemplate.getForEntity(
            createURLWithPort("/api/users/" + userId), 
            UserDto.class
        );
        
        assertEquals(HttpStatus.NOT_FOUND, getResponse.getStatusCode());
    }
}