// tests/e2e/UserRegistrationE2ETest.java
package com.selimhorri.app.e2e;

import com.selimhorri.app.business.user.model.dto.UserDto;
import com.selimhorri.app.business.user.model.dto.LoginDto;
import com.selimhorri.app.business.user.model.dto.TokenDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.annotation.DirtiesContext;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("e2e")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class UserRegistrationE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testCompleteUserRegistrationAndLoginFlow() {
        // Given
        UserDto registrationDto = new UserDto();
        registrationDto.setUsername("e2euser");
        registrationDto.setEmail("e2e@test.com");
        registrationDto.setFirstName("E2E");
        registrationDto.setLastName("Test");
        registrationDto.setPassword("password123");

        // When - Register user through API Gateway/Proxy
        ResponseEntity<UserDto> registrationResponse = restTemplate.postForEntity(
            createURLWithPort("/app/api/users/register"),
            registrationDto,
            UserDto.class
        );

        // Then - Verify registration
        assertEquals(HttpStatus.CREATED, registrationResponse.getStatusCode());
        assertNotNull(registrationResponse.getBody());
        assertNotNull(registrationResponse.getBody().getId());
        assertEquals("e2euser", registrationResponse.getBody().getUsername());

        // When - Login user
        LoginDto loginDto = new LoginDto();
        loginDto.setUsername("e2euser");
        loginDto.setPassword("password123");

        ResponseEntity<TokenDto> loginResponse = restTemplate.postForEntity(
            createURLWithPort("/app/api/auth/login"),
            loginDto,
            TokenDto.class
        );

        // Then - Verify login
        assertEquals(HttpStatus.OK, loginResponse.getStatusCode());
        assertNotNull(loginResponse.getBody());
        assertNotNull(loginResponse.getBody().getToken());
        assertFalse(loginResponse.getBody().getToken().isEmpty());

        // When - Access protected resource with token
        String token = loginResponse.getBody().getToken();
        // Additional verification can be added here for authenticated endpoints
    }

    @Test
    void testUserProfileManagement() {
        // Given - Register user
        UserDto registrationDto = new UserDto();
        registrationDto.setUsername("profileuser");
        registrationDto.setEmail("profile@test.com");
        registrationDto.setFirstName("Profile");
        registrationDto.setLastName("User");
        registrationDto.setPassword("password123");

        ResponseEntity<UserDto> registrationResponse = restTemplate.postForEntity(
            createURLWithPort("/app/api/users/register"),
            registrationDto,
            UserDto.class
        );

        UserDto registeredUser = registrationResponse.getBody();

        // When - Update profile
        registeredUser.setFirstName("Updated");
        registeredUser.setLastName("Profile");

        restTemplate.put(
            createURLWithPort("/app/api/users/" + registeredUser.getId()),
            registeredUser
        );

        // Then - Verify profile updated
        ResponseEntity<UserDto> updatedResponse = restTemplate.getForEntity(
            createURLWithPort("/app/api/users/" + registeredUser.getId()),
            UserDto.class
        );

        assertEquals(HttpStatus.OK, updatedResponse.getStatusCode());
        assertEquals("Updated", updatedResponse.getBody().getFirstName());
        assertEquals("Profile", updatedResponse.getBody().getLastName());
    }
}
