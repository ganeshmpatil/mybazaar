class ApiConfig {
  // Android emulator: 10.0.2.2 maps to host localhost
  // iOS simulator: localhost works directly
  // Physical device: use your machine's IP
  // Web: use localhost directly
  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api/v1';

  static String get authUrl => '$baseUrl$apiPrefix/auth';
  static String get productsUrl => '$baseUrl$apiPrefix/products';
  static String get cartUrl => '$baseUrl$apiPrefix/cart';
  static String get ordersUrl => '$baseUrl$apiPrefix/orders';
  static String get deliveryUrl => '$baseUrl$apiPrefix/delivery';
}
