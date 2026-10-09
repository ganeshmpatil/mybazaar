import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers({bool auth = false, String? authToken}) {
    final headers = {'Content-Type': 'application/json'};
    final t = authToken ?? _token;
    if (auth && t != null) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    String message = 'Something went wrong';
    try {
      final body = jsonDecode(response.body);
      message = body['detail'] ?? message;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }

  // ─── Auth ────────────────────────────────────────────

  Future<void> sendOtp(String mobile) async {
    final resp = await http.post(
      Uri.parse('${ApiConfig.authUrl}/send-otp'),
      headers: _headers(),
      body: jsonEncode({'mobile': mobile}),
    );
    await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final resp = await http.post(
      Uri.parse('${ApiConfig.authUrl}/verify-otp'),
      headers: _headers(),
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    );
    return await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final t = await token;
    final resp = await http.get(
      Uri.parse('${ApiConfig.authUrl}/profile'),
      headers: _headers(auth: true, authToken: t),
    );
    return await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final t = await token;
    final resp = await http.put(
      Uri.parse('${ApiConfig.authUrl}/profile'),
      headers: _headers(auth: true, authToken: t),
      body: jsonEncode(data),
    );
    return await _handleResponse(resp);
  }

  Future<List<dynamic>> getAddresses() async {
    final t = await token;
    final resp = await http.get(
      Uri.parse('${ApiConfig.authUrl}/addresses'),
      headers: _headers(auth: true, authToken: t),
    );
    return await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> data) async {
    final t = await token;
    final resp = await http.post(
      Uri.parse('${ApiConfig.authUrl}/addresses'),
      headers: _headers(auth: true, authToken: t),
      body: jsonEncode(data),
    );
    return await _handleResponse(resp);
  }

  // ─── Products ────────────────────────────────────────

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 20,
    int? categoryId,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse(ApiConfig.productsUrl).replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers());
    return await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getProductDetail(int id) async {
    final resp = await http.get(
      Uri.parse('${ApiConfig.productsUrl}/$id'),
      headers: _headers(),
    );
    return await _handleResponse(resp);
  }

  Future<List<dynamic>> getCategories() async {
    final resp = await http.get(
      Uri.parse('${ApiConfig.productsUrl}/categories'),
      headers: _headers(),
    );
    return await _handleResponse(resp);
  }

  // ─── Cart ───────────────────────────────────────────

  Future<Map<String, dynamic>> getCart() async {
    final t = await token;
    final resp = await http.get(
      Uri.parse(ApiConfig.cartUrl),
      headers: _headers(auth: true, authToken: t),
    );
    return await _handleResponse(resp);
  }

  Future<void> addToCart(int productId, double quantity) async {
    final t = await token;
    final resp = await http.post(
      Uri.parse(ApiConfig.cartUrl),
      headers: _headers(auth: true, authToken: t),
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    await _handleResponse(resp);
  }

  Future<void> updateCartItem(int itemId, double quantity) async {
    final t = await token;
    final resp = await http.put(
      Uri.parse('${ApiConfig.cartUrl}/$itemId'),
      headers: _headers(auth: true, authToken: t),
      body: jsonEncode({'quantity': quantity}),
    );
    await _handleResponse(resp);
  }

  Future<void> removeCartItem(int itemId) async {
    final t = await token;
    final resp = await http.delete(
      Uri.parse('${ApiConfig.cartUrl}/$itemId'),
      headers: _headers(auth: true, authToken: t),
    );
    await _handleResponse(resp);
  }

  // ─── Orders ─────────────────────────────────────────

  Future<Map<String, dynamic>> createOrder({
    required int addressId,
    String? deliverySlot,
    String? couponCode,
    String? notes,
  }) async {
    final t = await token;
    final body = <String, dynamic>{'address_id': addressId};
    if (deliverySlot != null) body['delivery_slot'] = deliverySlot;
    if (couponCode != null) body['coupon_code'] = couponCode;
    if (notes != null) body['notes'] = notes;

    final resp = await http.post(
      Uri.parse(ApiConfig.ordersUrl),
      headers: _headers(auth: true, authToken: t),
      body: jsonEncode(body),
    );
    return await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getOrders({int page = 1}) async {
    final t = await token;
    final uri = Uri.parse(ApiConfig.ordersUrl)
        .replace(queryParameters: {'page': page.toString()});
    final resp = await http.get(
      uri,
      headers: _headers(auth: true, authToken: t),
    );
    return await _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final t = await token;
    final resp = await http.get(
      Uri.parse('${ApiConfig.ordersUrl}/$orderId'),
      headers: _headers(auth: true, authToken: t),
    );
    return await _handleResponse(resp);
  }

  Future<void> cancelOrder(int orderId) async {
    final t = await token;
    final resp = await http.post(
      Uri.parse('${ApiConfig.ordersUrl}/$orderId/cancel'),
      headers: _headers(auth: true, authToken: t),
    );
    await _handleResponse(resp);
  }
}
