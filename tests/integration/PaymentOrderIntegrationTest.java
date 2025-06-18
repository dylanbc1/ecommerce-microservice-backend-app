package com.selimhorri.app.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import com.selimhorri.app.business.order.model.dto.OrderDto;
import com.selimhorri.app.business.payment.model.dto.PaymentDto;
import com.selimhorri.app.business.payment.model.PaymentStatus;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("integration")
class PaymentOrderIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testCompletePaymentFlow_ShouldProcessOrderPayment() {
        // Given - Create order first
        OrderDto orderDto = new OrderDto();
        orderDto.setOrderDesc("Integration test order for payment");
        orderDto.setOrderFee(599.99);
        
        ResponseEntity<OrderDto> orderResponse = restTemplate.postForEntity(
            createURLWithPort("/api/orders"), orderDto, OrderDto.class);
        
        assertEquals(HttpStatus.CREATED, orderResponse.getStatusCode());
        OrderDto createdOrder = orderResponse.getBody();

        // When - Process payment for the order
        PaymentDto paymentDto = new PaymentDto();
        paymentDto.setOrderId(createdOrder.getOrderId());
        paymentDto.setPaymentStatus(PaymentStatus.PENDING);
        paymentDto.setIsPayed(false);

        ResponseEntity<PaymentDto> paymentResponse = restTemplate.postForEntity(
            createURLWithPort("/api/payments"), paymentDto, PaymentDto.class);

        // Then - Verify payment was processed
        assertEquals(HttpStatus.CREATED, paymentResponse.getStatusCode());
        assertNotNull(paymentResponse.getBody());
        assertEquals(createdOrder.getOrderId(), paymentResponse.getBody().getOrderId());
        
        // Verify payment can be retrieved
        ResponseEntity<PaymentDto> getPaymentResponse = restTemplate.getForEntity(
            createURLWithPort("/api/payments/" + paymentResponse.getBody().getPaymentId()),
            PaymentDto.class);
        
        assertEquals(HttpStatus.OK, getPaymentResponse.getStatusCode());
        assertEquals(createdOrder.getOrderId(), getPaymentResponse.getBody().getOrderId());
    }

    @Test
    void testPaymentFailure_ShouldMaintainOrderIntegrity() {
        // Given - Create order
        OrderDto orderDto = new OrderDto();
        orderDto.setOrderDesc("Order for failed payment test");
        orderDto.setOrderFee(1299.99);
        
        ResponseEntity<OrderDto> orderResponse = restTemplate.postForEntity(
            createURLWithPort("/api/orders"), orderDto, OrderDto.class);
        
        OrderDto createdOrder = orderResponse.getBody();

        // When - Attempt payment with invalid data
        PaymentDto invalidPaymentDto = new PaymentDto();
        invalidPaymentDto.setOrderId(999999); // Non-existent order
        invalidPaymentDto.setPaymentStatus(PaymentStatus.PENDING);

        ResponseEntity<PaymentDto> paymentResponse = restTemplate.postForEntity(
            createURLWithPort("/api/payments"), invalidPaymentDto, PaymentDto.class);

        // Then - Verify original order is still intact
        ResponseEntity<OrderDto> verifyOrderResponse = restTemplate.getForEntity(
            createURLWithPort("/api/orders/" + createdOrder.getOrderId()),
            OrderDto.class);
        
        assertEquals(HttpStatus.OK, verifyOrderResponse.getStatusCode());
        assertEquals("Order for failed payment test", verifyOrderResponse.getBody().getOrderDesc());
    }
}
