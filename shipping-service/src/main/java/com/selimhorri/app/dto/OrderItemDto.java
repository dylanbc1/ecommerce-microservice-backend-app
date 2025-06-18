package com.selimhorri.app.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class OrderItemDto implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer productId;
    private Integer orderId;
    private Integer orderedQuantity;
    private ProductDto productDto;
    private OrderDto orderDto;
}
