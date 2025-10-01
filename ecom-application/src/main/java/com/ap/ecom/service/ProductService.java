package com.ap.ecom.service;

import java.util.List;
import java.util.Optional;

import com.ap.ecom.dto.ProductRequest;
import com.ap.ecom.dto.ProductResponse;

public interface ProductService {
    ProductResponse createProduct(ProductRequest product);
    Optional<ProductResponse> updateProduct(Long id, ProductRequest productRequest);
    List<ProductResponse> getAllProducts();
    boolean deleteProduct(Long id);
    List<ProductResponse> searchProducts(String keyword);
    Optional<ProductResponse> getProductById(String id);

}
