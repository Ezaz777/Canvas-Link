/// WallpaperSync — Authentication Service
/// Manages secure token storage using flutter_secure_storage.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _tokenKey = 'wallpaper_sync_jwt';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  /// Save the JWT token securely.
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      print('AuthService: Error writing token: $e');
    }
  }

  /// Retrieve the stored JWT token.
  /// Returns null if not logged in or on KeyStore read error.
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('AuthService: Error reading token: $e');
      return null;
    }
  }

  /// Delete the stored token (logout).
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      print('AuthService: Error deleting token: $e');
    }
  }

  /// Check if the user is logged in (has a stored token).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data.
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('AuthService: Error clearing storage: $e');
    }
  }
}
