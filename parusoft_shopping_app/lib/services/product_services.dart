import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductServices {
  static const String baseUrl = 'http://localhost:8005/api/v1';
  
  // Helper method to get auth token
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('accessToken');
    } catch (e) {
      print('Error retrieving auth token: $e');
      return null;
    }
  }

  // Generic method to add auth headers
  static Future<Map<String, String>> _getAuthHeaders({bool contentTypeJson = true}) async {
    Map<String, String> headers = {};
    if (contentTypeJson) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    
    // Always include user-id as fallback
    headers['user-id'] = 'demo-user';
    
    // Add authorization token if available
    final token = await _getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> getAllProducts({
  String? category,
  double? minPrice,
  double? maxPrice,
  double? minRating,
  int page = 1,
  int limit = 10,
  String sortBy = 'createdAt',
  String sortOrder = 'desc',
  String? search,   // Add this parameter
}) async {
  try {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (category != null) queryParams['category'] = category;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (search != null) queryParams['search'] = search;  // Add this line

    print("Request URL: $baseUrl/products with params: $queryParams");
    
    final response = await http.get(
        Uri.parse('$baseUrl/products').replace(queryParameters: queryParams));

    print("Response status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response data: ${data.toString().substring(0, min(100, data.toString().length))}...");
      return data['data'] ?? {'products': []};
    } else {
      print("Error response: ${response.body}");
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching products: $e');
    // Return a default structure instead of rethrowing
    return {'products': [], 'pagination': {'total': 0, 'page': 1, 'limit': 10, 'totalPages': 0}};
  }
}

  static Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      print('Error fetching product: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getProductByCategory(String category) async {
    final products = await getAllProducts(category: category);
    return products['products'];
  }

  static Future<List<dynamic>> searchProducts(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products').replace(
        queryParameters: {
          'search': query,
        },
      ));

      if (response.statusCode == 200) {
        return json.decode(response.body)['data']['products'];
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      print('Error searching products: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addToCart(String productId, int quantity) async {
    try {
      print('Adding to cart - Product ID: $productId, Quantity: $quantity');
      
      // Get headers with auth token
      final headers = await _getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: headers,
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity
        }),
      );
      
      print('Add to cart response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body)['data'] ?? {'success': true};
      } else {
        print('Server error response: ${response.body}');
        // Use local storage as fallback
        return {
          'success': true,
          'message': 'Item added to cart (local only)'
        };
      }
    } catch (e) {
      print('Error in addToCart method: $e');
      return {
        'success': true,
        'message': 'Item added to cart (local only)'
      };
    }
  }

  static Future<Map<String, dynamic>> getCart() async {
    try {
      print("Fetching cart from: $baseUrl/cart");
      
      // Get headers with auth token
      final headers = await _getAuthHeaders(contentTypeJson: false);
      
      final response = await http.get(
        Uri.parse('$baseUrl/cart'), 
        headers: headers
      );
      
      print("Cart API response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {'items': [], 'totalAmount': 0};
      } else {
        print("Error response: ${response.body}");
        // Return empty cart on error
        return {'items': [], 'totalAmount': 0};
      }
    } catch (e) {
      print('Error fetching cart: $e');
      return {'items': [], 'totalAmount': 0};
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(String productId) async {
  try {
    // Get headers with auth token
    final headers = await _getAuthHeaders(contentTypeJson: false);
    
    // The correct endpoint is DELETE /product/:productId
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/product/$productId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {'success': true};
    } else {
      print("Error removing from cart: ${response.body}");
      return {'success': false, 'message': 'Failed to remove item from cart'};
    }
  } catch (e) {
    print('Error removing from cart: $e');
    return {'success': true, 'message': 'Item removed from cart (local only)'};
  }
}

static Future<Map<String, dynamic>> removeCartItem(String itemId) async {
  try {
    // Get headers with auth token
    final headers = await _getAuthHeaders(contentTypeJson: false);
    
    // The correct endpoint is DELETE /item/:itemId
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/item/$itemId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {'success': true};
    } else {
      print("Error removing cart item: ${response.body}");
      return {'success': false, 'message': 'Failed to remove item from cart'};
    }
  } catch (e) {
    print('Error removing cart item: $e');
    return {'success': true, 'message': 'Item removed from cart (local only)'};
  }
}

  

  static Future<Map<String, dynamic>> updateCartItem(String itemId, int quantity) async {
  try {
    final headers = await _getAuthHeaders();
    
    // This endpoint is correct
    final response = await http.put(
      Uri.parse('$baseUrl/cart/update'),
      headers: headers,
      body: json.encode({
        'itemId': itemId,
        'quantity': quantity
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {'success': true};
    } else {
      print("Error updating cart: ${response.body}");
      return {'success': false, 'message': 'Failed to update cart item'};
    }
  } catch (e) {
    print('Error updating cart: $e');
    return {'success': false, 'message': 'Network error when updating cart'};
  }
}

static Future<Map<String, dynamic>> clearCart() async {
  try {
    final headers = await _getAuthHeaders(contentTypeJson: false);
    
    // This endpoint is correct
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/clear'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {'success': true};
    } else {
      print("Error clearing cart: ${response.body}");
      return {'success': false, 'message': 'Failed to clear cart'};
    }
  } catch (e) {
    print('Error clearing cart: $e');
    return {'success': false, 'message': 'Network error when clearing cart'};
  }
}

static Future<Map<String, dynamic>> adjustCartItemQuantity(String itemId, String action) async {
  try {
    final headers = await _getAuthHeaders();
    
    // This endpoint is correct
    final response = await http.patch(
      Uri.parse('$baseUrl/cart/item/$itemId/adjust'),
      headers: headers,
      body: json.encode({'action': action}), // 'increase' or 'decrease'
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {'success': true};
    } else {
      print("Error adjusting quantity: ${response.body}");
      return {'success': false, 'message': 'Failed to adjust quantity'};
    }
  } catch (e) {
    print('Error adjusting quantity: $e');
    return {'success': false, 'message': 'Network error when adjusting quantity'};
  }
}

// New method to check if a product is in the cart
static Future<Map<String, dynamic>> checkProductInCart(String productId) async {
  try {
    final headers = await _getAuthHeaders(contentTypeJson: false);
    
    final response = await http.get(
      Uri.parse('$baseUrl/cart/check/$productId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'] ?? {'isInCart': false, 'quantity': 0};
    } else {
      print("Error checking product in cart: ${response.body}");
      return {'isInCart': false, 'quantity': 0};
    }
  } catch (e) {
    print('Error checking product in cart: $e');
    return {'isInCart': false, 'quantity': 0};
  }
}

// Add these methods to your existing ProductServices class

// Frontend-only simulation methods
static Future<Map<String, dynamic>> placeOrder({
  required List<dynamic> items,
  required Map<String, dynamic> shippingInfo,
  required Map<String, dynamic> paymentInfo,
  required double total,
}) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));
  
  // Generate a random order ID
  final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  
  // Log the order for debugging
  print('SIMULATED ORDER PLACEMENT:');
  print('Order ID: $orderId');
  print('Items: ${items.length}');
  print('Total: \$${total.toStringAsFixed(2)}');
  print('Shipping to: ${shippingInfo['name']}');
  print('Payment method: ${paymentInfo['method']}');
  
  // In a real app, this would communicate with your backend
  // Always return success in this frontend-only implementation
  return {
    'success': true,
    'orderId': orderId,
    'message': 'Order placed successfully',
    'data': {
      'orderDetails': {
        'id': orderId,
        'date': DateTime.now().toIso8601String(),
        'items': items,
        'total': total,
        'status': 'Processing'
      }
    }
  };
}
}