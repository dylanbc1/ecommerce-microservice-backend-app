package com.selimhorri.app.e2e;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import com.selimhorri.app.business.user.model.dto.UserDto;
import com.selimhorri.app.business.product.model.dto.ProductDto;
import com.selimhorri.app.business.order.model.dto.OrderDto;
import com.selimhorri.app.business.payment.model.dto.PaymentDto;
import com.selimhorri.app.business.payment.model.PaymentStatus;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("e2e")
class OrderWorkflowE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testCompleteOrderWorkflow_FromProductToPayment() {
        // Step 1: Create user
        UserDto user = createUser();
        assertNotNull(user.getId());

        // Step 2: Create product
        ProductDto product = createProduct();
        assertNotNull(product.getId());
        
        // Step 3: Validate stock availability
        assertTrue(product.getStock() > 0);

        // Step 4: Create order
        OrderDto order = createOrder(user.getId(), product.getId());
        assertNotNull(order.getId());

        // Step 5: Process payment
        PaymentDto payment = processPayment(order.getId(), product.getPrice());
        assertNotNull(payment.getId());
        assertEquals(PaymentStatus.COMPLETED, payment.getStatus());

        // Step 6: Verify order status updated
        OrderDto finalOrder = getOrder(order.getId());
        assertEquals("PAID", finalOrder.getStatus());

        // Step 7: Verify stock was updated
        ProductDto finalProduct = getProduct(product.getId());
        assertEquals(product.getStock() - 1, finalProduct.getStock());
    }

    @Test
    void testOrderWorkflow_InsufficientStock_ShouldFail() {
        // Given
        UserDto user = createUser();
        ProductDto product = createProductWithLimitedStock(0);

        // When - Try to create order with no stock
        OrderDto orderDto = new OrderDto();
        orderDto.setUserId(user.getId());
        orderDto.setProductId(product.getId());
        orderDto.setQuantity(1);

        ResponseEntity<OrderDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/orders"), orderDto, OrderDto.class);

        // Then - Order should fail or be rejected
        assertTrue(response.getStatusCode().is4xxClientError() || 
                  (response.getStatusCode().is2xxSuccessful() && 
                   "REJECTED".equals(response.getBody().getStatus())));
    }

    private UserDto createUser() {
        UserDto userDto = new UserDto();
        userDto.setUsername("e2euser");
        userDto.setEmail("e2e@test.com");
        userDto.setFirstName("E2E");
        userDto.setLastName("Test");

        ResponseEntity<UserDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/users"), userDto, UserDto.class);
        
        return response.getBody();
    }

    private ProductDto createProduct() {
        ProductDto productDto = new ProductDto();
        productDto.setName("E2E Test Product");
        productDto.setPrice(BigDecimal.valueOf(99.99));
        productDto.setStock(10);

        ResponseEntity<ProductDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/products"), productDto, ProductDto.class);
        
        return response.getBody();
    }

    private ProductDto createProductWithLimitedStock(int stock) {
        ProductDto productDto = new ProductDto();
        productDto.setName("Limited Stock Product");
        productDto.setPrice(BigDecimal.valueOf(199.99));
        productDto.setStock(stock);

        ResponseEntity<ProductDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/products"), productDto, ProductDto.class);
        
        return response.getBody();
    }

    private OrderDto createOrder(Long userId, Long productId) {
        OrderDto orderDto = new OrderDto();
        orderDto.setUserId(userId);
        orderDto.setProductId(productId);
        orderDto.setQuantity(1);

        ResponseEntity<OrderDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/orders"), orderDto, OrderDto.class);
        
        return response.getBody();
    }

    private PaymentDto processPayment(Long orderId, BigDecimal amount) {
        PaymentDto paymentDto = new PaymentDto();
        paymentDto.setOrderId(orderId);
        paymentDto.setAmount(amount);
        paymentDto.setPaymentMethod("CREDIT_CARD");

        ResponseEntity<PaymentDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/payments"), paymentDto, PaymentDto.class);
        
        return response.getBody();
    }

    private OrderDto getOrder(Long orderId) {
        ResponseEntity<OrderDto> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/orders/" + orderId), OrderDto.class);
        
        return response.getBody();
    }

    private ProductDto getProduct(Long productId) {
        ResponseEntity<ProductDto> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/products/" + productId), ProductDto.class);
        
        return response.getBody();
    }
}
