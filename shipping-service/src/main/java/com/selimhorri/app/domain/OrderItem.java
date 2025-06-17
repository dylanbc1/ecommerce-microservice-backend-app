package com.selimhorri.app.domain;

import com.selimhorri.app.domain.id.OrderItemId;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "order_items")
@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class OrderItem implements Serializable {

    private static final long serialVersionUID = 1L;

    @EmbeddedId
    private OrderItemId orderItemId;

    @Column(name = "ordered_quantity")
    private Integer orderedQuantity;

    @Column(name = "product_title")
    private String productTitle;

    @Column(name = "product_price")
    private Double productPrice;

    @Column(name = "product_image_url")
    private String productImageUrl;

    public Integer getProductId() {
        return orderItemId != null ? orderItemId.getProductId() : null;
    }

    public Integer getOrderId() {
        return orderItemId != null ? orderItemId.getOrderId() : null;
    }

    public void setProductId(Integer productId) {
        if (orderItemId == null) {
            orderItemId = new OrderItemId();
        }
        orderItemId.setProductId(productId);
    }

    public void setOrderId(Integer orderId) {
        if (orderItemId == null) {
            orderItemId = new OrderItemId();
        }
        orderItemId.setOrderId(orderId);
    }
}
