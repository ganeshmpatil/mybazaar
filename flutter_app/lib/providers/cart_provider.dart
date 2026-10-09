import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _api;

  Cart? _cart;
  bool _isLoading = false;

  CartProvider(this._api);

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  int get itemCount => _cart?.itemCount ?? 0;
  double get total => _cart?.total ?? 0;
  List<CartItem> get items => _cart?.items ?? [];

  Future<void> loadCart() async {
    try {
      final data = await _api.getCart();
      _cart = Cart.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addToCart(int productId, double quantity) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.addToCart(productId, quantity);
      await loadCart();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(int itemId, double quantity) async {
    try {
      await _api.updateCartItem(itemId, quantity);
      await loadCart();
    } catch (_) {}
  }

  Future<void> removeItem(int itemId) async {
    try {
      await _api.removeCartItem(itemId);
      await loadCart();
    } catch (_) {}
  }

  Future<Order> placeOrder({
    required int addressId,
    String? deliverySlot,
    String? couponCode,
    String? notes,
  }) async {
    final data = await _api.createOrder(
      addressId: addressId,
      deliverySlot: deliverySlot,
      couponCode: couponCode,
      notes: notes,
    );
    await loadCart(); // cart should be empty after order
    return Order.fromJson(data);
  }

  void clear() {
    _cart = null;
    notifyListeners();
  }
}
