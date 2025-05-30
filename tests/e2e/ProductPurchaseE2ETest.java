// tests/e2e/ProductPurchaseE2ETest.java
package com.selimhorri.app.e2e;

import com.selimhorri.app.business.user.model.dto.UserDto;
import com.selimhorri.app.business.product.model.dto.ProductDto;
import com.selimhorri.app.business.order.model.dto.OrderDto;
import com.selimhorri.app.business.payment.model.dto.PaymentDto;
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
@ActiveProfiles("e2e")
class ProductPurchaseE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testCompletePurchaseFlow() {
        // Given - Create user
        UserDto user = createTestUser();
        
        // Given - Create product
        ProductDto product = createTestProduct();

        // When - Create order
        OrderDto orderDto = new OrderDto();
        orderDto.setUserId(user.getId());
        orderDto.setDescription("E2E Test Order");

        ResponseEntity<OrderDto> orderResponse = restTemplate.postForEntity(
            createURLWithPort("/app/api/orders"),
            orderDto,
            OrderDto.class
        );

        assertEquals(HttpStatus.CREATED, orderResponse.getStatusCode());
        OrderDto createdOrder = orderResponse.getBody();

        // When - Process payment
        PaymentDto paymentDto = new PaymentDto();
        paymentDto.setOrderId(createdOrder.getId());
        paymentDto.setAmount(BigDecimal.valueOf(99.99));
        paymentDto.setPaymentMethod("CREDIT_CARD");

        ResponseEntity<PaymentDto> paymentResponse = restTemplate.postForEntity(
            createURLWithPort("/app/api/payments"),
            paymentDto,
            PaymentDto.class
        );

        // Then - Verify complete flow
        assertEquals(HttpStatus.OK, paymentResponse.getStatusCode());
        assertNotNull(paymentResponse.getBody());

        // Verify order status updated
        ResponseEntity<OrderDto> finalOrderResponse = restTemplate.getForEntity(
            createURLWithPort("/app/api/orders/" + createdOrder.getId()),
            OrderDto.class
        );

        assertEquals(HttpStatus.OK, finalOrderResponse.getStatusCode());
        // Additional assertions for order status can be added here
    }

    private UserDto createTestUser() {
        UserDto userDto = new UserDto();
        userDto.setUsername("purchaseuser");
        userDto.setEmail("purchase@test.com");
        userDto.setFirstName("Purchase");
        userDto.setLastName("User");

        ResponseEntity<UserDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/users"),
            userDto,
            UserDto.class
        );

        return response.getBody();
    }

    private ProductDto createTestProduct() {
        ProductDto productDto = new ProductDto();
        productDto.setName("E2E Test Product");
        productDto.setDescription("Product for E2E testing");
        productDto.setPrice(BigDecimal.valueOf(99.99));
        productDto.setStock(10);

        ResponseEntity<ProductDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/products"),
            productDto,
            ProductDto.class
        );

        return response.getBody();
    }
}