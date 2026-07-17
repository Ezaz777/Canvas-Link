/// WallpaperSync — API Service
/// Handles all HTTP communication with the Cloudflare Workers backend.

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Replace with your deployed Cloudflare Worker URL
  static const String baseUrl = 'https://wallpaper-sync-api.canvaslink.workers.dev';

  final String? _token;

  ApiService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Fetch today's wallpaper URL from the backend.
  /// Returns a Map with 'image_url', 'pin_id', 'date', etc.
  /// Throws [PaymentRequiredException] if subscription is not active.
  /// Throws [UnauthorizedException] if token is invalid/expired.
  Future<Map<String, dynamic>> getWallpaper() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/get-wallpaper?device_type=mobile'),
      headers: _headers,
    );

    if (response.statusCode == 402) {
      throw PaymentRequiredException(
        'Premium subscription required. Please subscribe to access daily wallpapers.',
      );
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['error'] ?? 'Failed to fetch wallpaper',
        response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  /// Create a Stripe Checkout session for premium subscription.
  /// Returns the checkout URL.
  Future<String> createCheckout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/checkout'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['error'] ?? 'Failed to create checkout session',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    return data['checkout_url'];
  }

  /// Set the user's Pinterest board ID.
  Future<void> setBoard(String boardId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/set-board'),
      headers: _headers,
      body: jsonEncode({'board_id': boardId, 'device_type': 'mobile'}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['error'] ?? 'Failed to set board',
        response.statusCode,
      );
    }
  }

  /// Skip the current wallpaper and force the cycle forward.
  Future<void> skipWallpaper() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/skip-wallpaper'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['error'] ?? 'Failed to skip wallpaper',
        response.statusCode,
      );
    }
  }

  /// Get the Pinterest OAuth URL for login.
  static String getAuthUrl() => '$baseUrl/auth/pinterest';
}

// =============================================================================
// Custom Exceptions
// =============================================================================

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class PaymentRequiredException extends ApiException {
  PaymentRequiredException(String message) : super(message, 402);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}
