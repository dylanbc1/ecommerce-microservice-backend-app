package com.selimhorri.app.service.impl;

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.repository.OrderItemRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Shipping Service Implementation Tests")
class ShippingServiceImplTest {

    @Mock
    private OrderItemRepository orderItemRepository;

    @InjectMocks
    private OrderItemServiceImpl orderItemService;

    private OrderItem orderItem;
    private OrderItemDto orderItemDto;
    private OrderItemId orderItemId;

    @BeforeEach
    void setUp() {
        orderItemId = new OrderItemId(1, 1);
        
        orderItem = OrderItem.builder()
                .orderItemId(orderItemId)
                .orderedQuantity(2)
                .productTitle("Test Product")
                .productPrice(99.99)
                .productImageUrl("http://example.com/image.jpg")
                .build();

        orderItemDto = OrderItemDto.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(2)
                .build();
    }

   

 

    @Test
    @DisplayName("Should save order item")
    void shouldSaveOrderItem() {
        // Given
        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(orderItem);

        // When
        OrderItemDto result = orderItemService.save(orderItemDto);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getProductId());
        assertEquals(1, result.getOrderId());
        verify(orderItemRepository).save(any(OrderItem.class));
    }

    @Test
    @DisplayName("Should update order item")
    void shouldUpdateOrderItem() {
        // Given
        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(orderItem);

        // When
        OrderItemDto result = orderItemService.update(orderItemDto);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getProductId());
        assertEquals(1, result.getOrderId());
        verify(orderItemRepository).save(any(OrderItem.class));
    }


    @Test
    @DisplayName("Should delete order item by id")
    void shouldDeleteOrderItemById() {
        // Given
        doNothing().when(orderItemRepository).deleteById(orderItemId);

        // When & Then
        assertDoesNotThrow(() -> orderItemService.deleteById(orderItemId));
        verify(orderItemRepository).deleteById(orderItemId);
    }



    @Test
    @DisplayName("Should validate order item data")
    void shouldValidateOrderItemData() {
        // Test validation logic
        assertTrue(orderItem.getOrderedQuantity() > 0, "Quantity should be positive");
        assertNotNull(orderItem.getProductTitle(), "Product title should not be null");
        assertTrue(orderItem.getProductPrice() > 0, "Price should be positive");
        assertNotNull(orderItem.getOrderItemId(), "Order item ID should not be null");
    }

    @Test
    @DisplayName("Should handle edge cases")
    void shouldHandleEdgeCases() {
        // Test with null values
        OrderItem emptyItem = new OrderItem();
        assertNull(emptyItem.getProductId());
        assertNull(emptyItem.getOrderId());

        // Test with zero quantity
        OrderItem zeroQuantityItem = OrderItem.builder()
                .orderItemId(new OrderItemId(1, 1))
                .orderedQuantity(0)
                .build();
        assertEquals(0, zeroQuantityItem.getOrderedQuantity());

        // Test ID creation
        OrderItemId newId = new OrderItemId(2, 3);
        assertEquals(2, newId.getProductId());
        assertEquals(3, newId.getOrderId());
    }
}
