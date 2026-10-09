import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  List<Address> _addresses = [];

  AuthProvider(this._api);

  AuthStatus get status => _status;
  User? get user => _user;
  List<Address> get addresses => _addresses;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    final token = await _api.token;
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await _api.getProfile();
      _user = User.fromJson(data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      await _api.clearToken();
    }
    notifyListeners();
  }

  Future<void> sendOtp(String mobile) async {
    await _api.sendOtp(mobile);
  }

  Future<AuthResponse> verifyOtp(String mobile, String otp) async {
    final data = await _api.verifyOtp(mobile, otp);
    final authResp = AuthResponse.fromJson(data);
    await _api.setToken(authResp.accessToken);
    _user = User(
      id: authResp.userId,
      mobile: mobile,
      name: authResp.name,
      role: 'customer',
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
    return authResp;
  }

  Future<void> loadProfile() async {
    try {
      final data = await _api.getProfile();
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateProfile(String name, String? email) async {
    final data = <String, dynamic>{'name': name};
    if (email != null) data['email'] = email;
    final resp = await _api.updateProfile(data);
    _user = User.fromJson(resp);
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    try {
      final data = await _api.getAddresses();
      _addresses = data.map((e) => Address.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<Address> addAddress({
    required String fullAddress,
    String? label,
    String? pincode,
    String? city,
    bool isDefault = true,
    double? latitude,
    double? longitude,
  }) async {
    final data = {
      'full_address': fullAddress,
      'label': label,
      'pincode': pincode,
      'city': city,
      'is_default': isDefault,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final resp = await _api.addAddress(data);
    final address = Address.fromJson(resp);
    await loadAddresses();
    return address;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _addresses = [];
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
