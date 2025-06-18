package com.selimhorri.app.domain.id;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
@NoArgsConstructor
@AllArgsConstructor
@Data
public class OrderItemId implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer productId;
    private Integer orderId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        OrderItemId that = (OrderItemId) o;
        return Objects.equals(productId, that.productId) && 
               Objects.equals(orderId, that.orderId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(productId, orderId);
    }

    @Override
    public String toString() {
        return "OrderItemId{" +
                "productId=" + productId +
                ", orderId=" + orderId +
                '}';
    }
}











