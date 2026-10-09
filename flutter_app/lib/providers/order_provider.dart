import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api;

  List<Order> _orders = [];
  bool _isLoading = false;
  int _total = 0;

  OrderProvider(this._api);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  int get total => _total;

  Future<void> loadOrders({bool refresh = false}) async {
    _isLoading = true;
    if (refresh) notifyListeners();

    try {
      final data = await _api.getOrders();
      _orders = (data['items'] as List<dynamic>)
          .map((e) => Order.fromJson(e))
          .toList();
      _total = data['total'];
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Order?> getOrderDetail(int orderId) async {
    try {
      final data = await _api.getOrderDetail(orderId);
      return Order.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelOrder(int orderId) async {
    await _api.cancelOrder(orderId);
    await loadOrders(refresh: true);
  }
}
