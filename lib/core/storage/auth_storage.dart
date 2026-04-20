import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_config.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async =>
      _storage.write(key: ApiConfig.tokenKey, value: token);

  static Future<String?> getToken() async =>
      _storage.read(key: ApiConfig.tokenKey);

  static Future<void> deleteToken() async =>
      _storage.delete(key: ApiConfig.tokenKey);

  static Future<void> saveCustomer(Map<String, dynamic> customer) async =>
      _storage.write(key: ApiConfig.customerKey, value: jsonEncode(customer));

  static Future<Map<String, dynamic>?> getCustomer() async {
    final raw = await _storage.read(key: ApiConfig.customerKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteCustomer() async =>
      _storage.delete(key: ApiConfig.customerKey);

  static Future<void> saveTheme(String theme) async =>
      _storage.write(key: 'theme_mode', value: theme);

  static Future<String?> getTheme() async =>
      _storage.read(key: 'theme_mode');

  static Future<void> saveNotificationSettings(bool enabled) async =>
      _storage.write(key: 'notifications_enabled', value: enabled.toString());

  static Future<bool> getNotificationSettings() async {
    final val = await _storage.read(key: 'notifications_enabled');
    return val != 'false'; // Default to true
  }

  static Future<void> clearAll() async => _storage.deleteAll();
}
