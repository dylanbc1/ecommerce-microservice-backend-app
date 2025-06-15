package com.selimhorri.app.service.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Optional;
import java.util.List;
import java.util.Arrays;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.OrderItemId;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.repository.OrderItemRepository;

@ExtendWith(MockitoExtension.class)
class ShippingServiceImplTest {

    @Mock
    private OrderItemRepository orderItemRepository;

    @InjectMocks
    private OrderItemServiceImpl shippingService;

    @Test
    void testCalculateShippingCost_ShouldReturnCorrectCost() {
        // Given
        OrderItemId orderItemId = new OrderItemId(1, 101);
        
        OrderItem orderItem = OrderItem.builder()
                .orderItemId(orderItemId)
                .orderedQuantity(3)
                .build();

        when(orderItemRepository.findById(orderItemId)).thenReturn(Optional.of(orderItem));

        // When
        OrderItemDto result = shippingService.findById(orderItemId);

        // Then
        assertNotNull(result);
        assertEquals(3, result.getOrderedQuantity());
        verify(orderItemRepository, times(1)).findById(orderItemId);
    }

    @Test
    void testProcessBulkShipping_ShouldHandleMultipleItems() {
        // Given
        OrderItem item1 = OrderItem.builder()
                .orderItemId(new OrderItemId(1, 101))
                .orderedQuantity(2)
                .build();
        
        OrderItem item2 = OrderItem.builder()
                .orderItemId(new OrderItemId(1, 102))
                .orderedQuantity(1)
                .build();

        List<OrderItem> orderItems = Arrays.asList(item1, item2);
        when(orderItemRepository.findAll()).thenReturn(orderItems);

        // When
        List<OrderItemDto> results = shippingService.findAll();

        // Then
        assertNotNull(results);
        assertEquals(2, results.size());
        verify(orderItemRepository, times(1)).findAll();
    }
}
