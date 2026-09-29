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
  /// Throws [UnauthorizedException] if token is invalid/expired.
  Future<Map<String, dynamic>> getWallpaper() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/get-wallpaper?device_type=mobile'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(
          body['message'] ?? body['error'] ?? 'Failed to fetch wallpaper',
          response.statusCode,
          body['code'] ?? body['error'],
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Failed to fetch wallpaper (Server error ${response.statusCode})',
          response.statusCode,
        );
      }
    }

    return jsonDecode(response.body);
  }

  /// Set or deactivate the user's Pinterest board ID.
  /// Pass null to deactivate the board for the specified device.
  Future<void> setBoard(String? boardId, [String deviceType = 'mobile']) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/set-board'),
      headers: _headers,
      body: jsonEncode({'board_id': boardId, 'device_type': deviceType}),
    );

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(
          body['message'] ?? body['error'] ?? 'Failed to update board',
          response.statusCode,
          body['code'] ?? body['error'],
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Failed to update board (${response.statusCode})',
          response.statusCode,
        );
      }
    }
  }

  /// Delete a pin from the user's Pinterest board.
  Future<void> deletePin(String pinId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/delete-pin/$pinId'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode == 403) {
      throw UnauthorizedException(
          'Permission denied. Please re-authenticate to grant delete permissions.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['error'] ?? 'Failed to delete pin',
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

  /// Get all pins from the user's selected board.
  Future<List<Map<String, dynamic>>> getBoardPins() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/board-pins?device_type=mobile'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw ApiException(
          body['message'] ?? body['error'] ?? 'Failed to fetch board pins',
          response.statusCode,
          body['code'] ?? body['error'],
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Failed to fetch board pins (${response.statusCode})',
          response.statusCode,
        );
      }
    }

    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['pins'] ?? []);
  }

  /// Get the user's Pinterest boards and selection state.
  Future<Map<String, dynamic>> getBoards() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/boards'),
      headers: _headers,
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
        body['error'] ?? 'Failed to fetch boards',
        response.statusCode,
      );
    }

    return jsonDecode(response.body);
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
  final String? code;

  ApiException(this.message, this.statusCode, [this.code]);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401, 'unauthorized');
}
