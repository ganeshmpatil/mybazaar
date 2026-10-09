import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api;

  List<Order> _orders = [];
  bool _isLoading = false;
  int _total = 0;
  String? _error;

  OrderProvider(this._api);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  int get total => _total;
  String? get error => _error;

  Future<void> loadOrders({bool refresh = false}) async {
    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      final data = await _api.getOrders();
      _orders = (data['items'] as List<dynamic>)
          .map((e) => Order.fromJson(e))
          .toList();
      _total = data['total'] ?? 0;
    } catch (e) {
      debugPrint('Failed to load orders: $e');
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Order?> getOrderDetail(int orderId) async {
    try {
      final data = await _api.getOrderDetail(orderId);
      return Order.fromJson(data);
    } catch (e) {
      debugPrint('Failed to load order $orderId: $e');
      return null;
    }
  }

  Future<void> cancelOrder(int orderId) async {
    await _api.cancelOrder(orderId);
    await loadOrders(refresh: true);
  }
}
