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
import com.selimhorri.app.business.cart.model.dto.CartDto;
import com.selimhorri.app.business.cart.model.dto.CartItemDto;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("e2e")
class CartManagementE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    @LocalServerPort
    private int port;

    private String createURLWithPort(String uri) {
        return "http://localhost:" + port + uri;
    }

    @Test
    void testCompleteCartFlow_AddModifyRemoveCheckout() {
        // Step 1: Create user and products
        UserDto user = createUser();
        ProductDto product1 = createProduct("Product 1", BigDecimal.valueOf(50.00));
        ProductDto product2 = createProduct("Product 2", BigDecimal.valueOf(75.00));

        // Step 2: Create cart for user
        CartDto cart = createCart(user.getId());
        assertNotNull(cart.getId());
        assertEquals(user.getId(), cart.getUserId());

        // Step 3: Add products to cart
        CartItemDto item1 = addProductToCart(cart.getId(), product1.getId(), 2);
        CartItemDto item2 = addProductToCart(cart.getId(), product2.getId(), 1);
        
        assertNotNull(item1.getId());
        assertNotNull(item2.getId());

        // Step 4: Verify cart contents
        CartDto cartWithItems = getCart(cart.getId());
        assertEquals(2, cartWithItems.getItems().size());
        
        BigDecimal expectedTotal = BigDecimal.valueOf(50.00 * 2 + 75.00 * 1); // 175.00
        assertEquals(expectedTotal, cartWithItems.getTotalAmount());

        // Step 5: Modify item quantity
        CartItemDto modifiedItem = updateCartItemQuantity(item1.getId(), 3);
        assertEquals(3, modifiedItem.getQuantity());

        // Step 6: Verify updated total
        CartDto updatedCart = getCart(cart.getId());
        BigDecimal newExpectedTotal = BigDecimal.valueOf(50.00 * 3 + 75.00 * 1); // 225.00
        assertEquals(newExpectedTotal, updatedCart.getTotalAmount());

        // Step 7: Remove an item
        removeCartItem(item2.getId());

        // Step 8: Verify item removed
        CartDto finalCart = getCart(cart.getId());
        assertEquals(1, finalCart.getItems().size());
        assertEquals(BigDecimal.valueOf(150.00), finalCart.getTotalAmount()); // 50.00 * 3

        // Step 9: Proceed to checkout
        ResponseEntity<String> checkoutResponse = restTemplate.postForEntity(
            createURLWithPort("/app/api/carts/" + cart.getId() + "/checkout"), 
            null, String.class);
        
        assertEquals(HttpStatus.OK, checkoutResponse.getStatusCode());
    }

    @Test
    void testCartPersistence_ShouldMaintainStateAcrossSessions() {
        // Given - Create user and cart with items
        UserDto user = createUser();
        ProductDto product = createProduct("Persistent Product", BigDecimal.valueOf(100.00));
        CartDto cart = createCart(user.getId());
        addProductToCart(cart.getId(), product.getId(), 1);

        // When - Simulate session restart by fetching cart again
        CartDto retrievedCart = getCart(cart.getId());

        // Then - Verify cart state is maintained
        assertNotNull(retrievedCart);
        assertEquals(1, retrievedCart.getItems().size());
        assertEquals(BigDecimal.valueOf(100.00), retrievedCart.getTotalAmount());
    }

    private UserDto createUser() {
        UserDto userDto = new UserDto();
        userDto.setUsername("cartuser" + System.currentTimeMillis());
        userDto.setEmail("cartuser@test.com");
        userDto.setFirstName("Cart");
        userDto.setLastName("User");

        ResponseEntity<UserDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/users"), userDto, UserDto.class);
        
        return response.getBody();
    }

    private ProductDto createProduct(String name, BigDecimal price) {
        ProductDto productDto = new ProductDto();
        productDto.setName(name);
        productDto.setPrice(price);
        productDto.setStock(20);

        ResponseEntity<ProductDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/products"), productDto, ProductDto.class);
        
        return response.getBody();
    }

    private CartDto createCart(Long userId) {
        CartDto cartDto = new CartDto();
        cartDto.setUserId(userId);

        ResponseEntity<CartDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/carts"), cartDto, CartDto.class);
        
        return response.getBody();
    }

    private CartItemDto addProductToCart(Long cartId, Long productId, int quantity) {
        CartItemDto cartItemDto = new CartItemDto();
        cartItemDto.setCartId(cartId);
        cartItemDto.setProductId(productId);
        cartItemDto.setQuantity(quantity);

        ResponseEntity<CartItemDto> response = restTemplate.postForEntity(
            createURLWithPort("/app/api/cart-items"), cartItemDto, CartItemDto.class);
        
        return response.getBody();
    }

    private CartDto getCart(Long cartId) {
        ResponseEntity<CartDto> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/carts/" + cartId), CartDto.class);
        
        return response.getBody();
    }

    private CartItemDto updateCartItemQuantity(Long itemId, int newQuantity) {
        CartItemDto updateDto = new CartItemDto();
        updateDto.setQuantity(newQuantity);

        restTemplate.put(createURLWithPort("/app/api/cart-items/" + itemId), updateDto);
        
        ResponseEntity<CartItemDto> response = restTemplate.getForEntity(
            createURLWithPort("/app/api/cart-items/" + itemId), CartItemDto.class);
        
        return response.getBody();
    }

    private void removeCartItem(Long itemId) {
        restTemplate.delete(createURLWithPort("/app/api/cart-items/" + itemId));
    }
}
