import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _devUrl = 'https://mybazaar-api.onrender.com';

  /// In release mode, use the same origin (relative URLs).
  /// In debug mode, use localhost.
  /// Override with --dart-define=API_BASE_URL=https://your-app.onrender.com
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kReleaseMode && kIsWeb) return ''; // same-origin
    return _devUrl;
  }

  static const String apiPrefix = '/api/v1';

  static String get authUrl => '$baseUrl$apiPrefix/auth';
  static String get productsUrl => '$baseUrl$apiPrefix/products';
  static String get cartUrl => '$baseUrl$apiPrefix/cart';
  static String get ordersUrl => '$baseUrl$apiPrefix/orders';
  static String get deliveryUrl => '$baseUrl$apiPrefix/delivery';
}
