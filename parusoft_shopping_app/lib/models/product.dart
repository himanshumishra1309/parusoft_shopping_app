import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ProductVariant {
  final String color;
  final String size;
  final int stock;

  ProductVariant({
    required this.color,
    required this.size,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}

class Review {
  final String user;
  final double rating;
  final String comment;
  final List<String>? images; // Add this property

  Review({
    required this.user,
    required this.rating,
    required this.comment,
    this.images, // Add this parameter
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Parse images if they exist in the JSON
    List<String>? imagesList;
    if (json['images'] != null) {
      imagesList = List<String>.from(json['images']);
    }

    return Review(
      user: json['user'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      images: imagesList, // Include images in the constructor
    );
  }
}

class Product {
  final dynamic id; // Can be either String or int depending on the source
  final String name;
  final String description;
  final double price;
  final double rating;
  final String category;
  final List<String> images;
  final int popularity;
  final String releaseDate;
  final List<ProductVariant> variants;
  final List<Review> reviews;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.popularity,
    required this.releaseDate,
    required this.variants,
    required this.images,
    required this.description,
    required this.reviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse variants safely
    List<ProductVariant> variants = [];
    if (json['variants'] != null) {
      variants = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    // Parse reviews safely
    List<Review> reviews = [];
    if (json['reviews'] != null) {
      reviews = (json['reviews'] as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return Product(
      // Accept both string and int IDs (from API or local JSON)
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Product',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      popularity: json['popularity'] ?? 0,
      releaseDate: json['release_date'] ?? json['releaseDate'] ?? '',
      variants: variants,
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      description: json['description'] ?? '',
      reviews: reviews,
    );
  }

  // Calculate average rating from the reviews
  double get averageRating {
    if (reviews.isEmpty) return rating; // Use the product rating if no reviews
    double sum = reviews.fold(0.0, (prev, review) => prev + review.rating);
    return sum / reviews.length;
  }

  // Check if product is in stock
  bool get isInStock {
    return variants.any((variant) => variant.stock > 0);
  }

  // Helper to get all available colors
  List<String> get availableColors {
    return variants.map((v) => v.color).toSet().toList();
  }
}

class ProductRepository {
  static Future<List<Product>> loadProducts() async {
    try {
      final String response = await rootBundle.loadString('assets/json_files/product_catalog_sample.json');
      final List<dynamic> jsonData = json.decode(response);
      return jsonData.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading products from local JSON: $e');
      return [];
    }
  }

  // Helper methods for filtering
  static List<String> getAllCategories(List<Product> products) {
    final Set<String> categories = products.map((p) => p.category).toSet();
    return ['All', ...categories];
  }
  
  static double getMinPrice(List<Product> products) {
    if (products.isEmpty) return 0.0;
    return products.fold<double>(
      double.infinity, 
      (prev, product) => product.price < prev ? product.price : prev
    );
  }
  
  static double getMaxPrice(List<Product> products) {
    if (products.isEmpty) return 1000.0;
    return products.fold<double>(
      0.0, 
      (prev, product) => product.price > prev ? product.price : prev
    );
  }
}