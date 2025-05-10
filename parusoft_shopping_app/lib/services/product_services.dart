import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductServices {
  static const String baseUrl = 'http://localhost:8005/api/v1';

  static Future<Map<String, dynamic>> getAllProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
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

      final response = await http.get(
          Uri.parse('$baseUrl/products').replace(queryParameters: queryParams));

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
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
      final response = await http.get(Uri.parse('$baseUrl/prroducts').replace(
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

  static Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/cart'), headers: {'user-id': 'demo-user'});

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to loacd cart');
      }
    } catch (e) {
      print('Error fetching cart: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addToCart(String productId, int quantity,
      {String? variantId}) async {
    try {
      final body = {
        'productId': productId,
        'quantity': quantity,
      };

      if (variantId != null) {
        body['variantId'] = variantId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {'Content-Type': 'application/json', 'user-id': 'demo-user'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to add product to cart');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }
}
