import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService{
  static const String baseUrl = 'http://localhost:8005/api/v1';

  Future<void> _saveTokens(String accessToken, String refreshToken) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
  
  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  // Clear tokens on logout
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async{
    try {
      final response = await http.post(Uri.parse('$baseUrl/users/register'),
      headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Registration successful'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Save tokens for future authenticated requests
        final accessToken = responseData['data']['accessToken'];
        final refreshToken = responseData['data']['refreshToken'];
        await _saveTokens(accessToken, refreshToken);
        
        return {
          'success': true,
          'user': responseData['data']['user'],
          'message': responseData['message'] ?? 'Login successful'
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logoutUser() async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No active session found'
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Clear tokens regardless of server response
      await clearTokens();
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Logged out successfully'
        };
      } else {
        return {
          'success': true, // Still consider successful since tokens are cleared locally
          'message': 'Logged out (locally)'
        };
      }
    } catch (e) {
      // Clear tokens on error anyway
      await clearTokens();
      return {
        'success': true, // Still consider successful since tokens are cleared locally
        'message': 'Logged out (locally)'
      };
    }
  }

  // Refresh access token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      
      if (refreshToken == null) {
        return {
          'success': false,
          'message': 'No refresh token found'
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Save new tokens
        final newAccessToken = responseData['data']['accessToken'];
        final newRefreshToken = responseData['data']['refreshToken'];
        await _saveTokens(newAccessToken, newRefreshToken);
        
        return {
          'success': true,
          'message': 'Token refreshed successfully'
        };
      } else {
        // Clear tokens on refresh failure
        await clearTokens();
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token refresh failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': responseData['data'],
          'message': responseData['message'] ?? 'Profile retrieved successfully'
        };
      } else if (response.statusCode == 401) {
        // Try refreshing token if unauthorized
        final refreshResult = await refreshToken();
        if (refreshResult['success']) {
          // Retry after token refresh
          return await getCurrentUser();
        } else {
          return {
            'success': false,
            'message': 'Session expired'
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to retrieve profile'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Update user details
  Future<Map<String, dynamic>> updateUserDetails({
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final token = await getAccessToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }
      
      // Create a map with only the fields to update
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      
      final response = await http.patch(
        Uri.parse('$baseUrl/users/update-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': responseData['data'],
          'message': responseData['message'] ?? 'Profile updated successfully'
        };
      } else if (response.statusCode == 401) {
        // Try refreshing token if unauthorized
        final refreshResult = await refreshToken();
        if (refreshResult['success']) {
          // Retry after token refresh
          return await updateUserDetails(name: name, phoneNumber: phoneNumber);
        } else {
          return {
            'success': false,
            'message': 'Session expired'
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }
}