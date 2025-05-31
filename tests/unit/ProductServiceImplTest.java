// tests/unit/ProductServiceImplTest.java
package com.selimhorri.app.business.product.service.impl;

import com.selimhorri.app.business.product.model.dto.ProductDto;
import com.selimhorri.app.business.product.model.entity.Product;
import com.selimhorri.app.business.product.repository.ProductRepository;
import com.selimhorri.app.business.product.service.impl.ProductServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    @Test
    void testFindById_ShouldReturnProductDto_WhenProductExists() {
        // Given
        Long productId = 1L;
        Product product = new Product();
        product.setId(productId);
        product.setName("Test Product");
        product.setDescription("Test Description");
        product.setPrice(BigDecimal.valueOf(29.99));
        product.setStock(10);

        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        // When
        ProductDto result = productService.findById(productId);

        // Then
        assertNotNull(result);
        assertEquals(productId, result.getId());
        assertEquals("Test Product", result.getName());
        assertEquals("Test Description", result.getDescription());
        assertEquals(BigDecimal.valueOf(29.99), result.getPrice());
        assertEquals(10, result.getStock());
        verify(productRepository, times(1)).findById(productId);
    }

    @Test
    void testFindAll_ShouldReturnProductList_WhenProductsExist() {
        // Given
        Product product1 = new Product();
        product1.setId(1L);
        product1.setName("Product 1");
        product1.setPrice(BigDecimal.valueOf(19.99));

        Product product2 = new Product();
        product2.setId(2L);
        product2.setName("Product 2");
        product2.setPrice(BigDecimal.valueOf(39.99));

        List<Product> products = Arrays.asList(product1, product2);
        when(productRepository.findAll()).thenReturn(products);

        // When
        List<ProductDto> result = productService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(2, result.size());
        assertEquals("Product 1", result.get(0).getName());
        assertEquals("Product 2", result.get(1).getName());
        verify(productRepository, times(1)).findAll();
    }

    @Test
    void testSaveProduct_ShouldReturnSavedProductDto_WhenValidData() {
        // Given
        ProductDto inputDto = new ProductDto();
        inputDto.setName("New Product");
        inputDto.setDescription("New Description");
        inputDto.setPrice(BigDecimal.valueOf(49.99));
        inputDto.setStock(5);

        Product savedProduct = new Product();
        savedProduct.setId(1L);
        savedProduct.setName("New Product");
        savedProduct.setDescription("New Description");
        savedProduct.setPrice(BigDecimal.valueOf(49.99));
        savedProduct.setStock(5);

        when(productRepository.save(any(Product.class))).thenReturn(savedProduct);

        // When
        ProductDto result = productService.save(inputDto);

        // Then
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("New Product", result.getName());
        assertEquals("New Description", result.getDescription());
        assertEquals(BigDecimal.valueOf(49.99), result.getPrice());
        assertEquals(5, result.getStock());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void testUpdateStock_ShouldUpdateProductStock_WhenValidQuantity() {
        // Given
        Long productId = 1L;
        int newStock = 15;
        
        Product product = new Product();
        product.setId(productId);
        product.setStock(10);

        Product updatedProduct = new Product();
        updatedProduct.setId(productId);
        updatedProduct.setStock(newStock);

        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(productRepository.save(any(Product.class))).thenReturn(updatedProduct);

        // When
        ProductDto result = productService.updateStock(productId, newStock);

        // Then
        assertNotNull(result);
        assertEquals(newStock, result.getStock());
        verify(productRepository, times(1)).findById(productId);
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void testSearchByName_ShouldReturnMatchingProducts_WhenNameProvided() {
        // Given
        String searchTerm = "laptop";
        Product product1 = new Product();
        product1.setId(1L);
        product1.setName("Gaming Laptop");

        Product product2 = new Product();
        product2.setId(2L);
        product2.setName("Business Laptop");

        List<Product> products = Arrays.asList(product1, product2);
        when(productRepository.findByNameContainingIgnoreCase(searchTerm)).thenReturn(products);

        // When
        List<ProductDto> result = productService.searchByName(searchTerm);

        // Then
        assertNotNull(result);
        assertEquals(2, result.size());
        assertTrue(result.get(0).getName().toLowerCase().contains("laptop"));
        assertTrue(result.get(1).getName().toLowerCase().contains("laptop"));
        verify(productRepository, times(1)).findByNameContainingIgnoreCase(searchTerm);
    }
}