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
      color: json['color'] as String,
      size: json['size'] as String,
      stock: json['stock'] as int,
    );
  }
}

class Review {
  final String user;
  final double rating;
  final String comment;

  Review({
    required this.user,
    required this.rating,
    required this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      user: json['user'] as String,
      rating: json['rating'].toDouble(),
      comment: json['comment'] as String,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int popularity;
  final String releaseDate;
  final List<ProductVariant> variants;
  final List<String> images;
  final String description;
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
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      price: json['price'].toDouble(),
      rating: json['rating'].toDouble(),
      popularity: json['popularity'] as int,
      releaseDate: json['release_date'] as String,
      variants: (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      images: List<String>.from(json['images']),
      description: json['description'] as String,
      reviews: (json['reviews'] as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  // Calculate average rating from the reviews
  double get averageRating {
    if (reviews.isEmpty) return 0.0;
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
    final String response = await rootBundle.loadString('assets/json_files/product_catalog_sample.json');
    final List<dynamic> jsonData = json.decode(response);
    return jsonData.map((json) => Product.fromJson(json)).toList();
  }

  // Helper methods for filtering
  static List<String> getAllCategories(List<Product> products) {
    final Set<String> categories = products.map((p) => p.category).toSet();
    return ['All', ...categories];
  }
  
  static double getMinPrice(List<Product> products) {
    if (products.isEmpty) return 0.0;
    return products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }
  
  static double getMaxPrice(List<Product> products) {
    if (products.isEmpty) return 1000.0;
    return products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }
}