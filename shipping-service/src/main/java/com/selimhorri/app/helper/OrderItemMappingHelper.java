package com.selimhorri.app.helper;

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.dto.ProductDto;

public interface OrderItemMappingHelper {

    static OrderItemDto map(final OrderItem orderItem) {
        return OrderItemDto.builder()
                .productId(orderItem.getProductId())
                .orderId(orderItem.getOrderId())
                .orderedQuantity(orderItem.getOrderedQuantity())
                .productDto(ProductDto.builder()
                        .productId(orderItem.getProductId())
                        .build())
                .orderDto(OrderDto.builder()
                        .orderId(orderItem.getOrderId())
                        .build())
                .build();
    }

    static OrderItem map(final OrderItemDto orderItemDto) {
        OrderItemId orderItemId = new OrderItemId(
                orderItemDto.getProductId(),
                orderItemDto.getOrderId()
        );
        
        return OrderItem.builder()
                .orderItemId(orderItemId)
                .orderedQuantity(orderItemDto.getOrderedQuantity())
                .build();
    }
}
