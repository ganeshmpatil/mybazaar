import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api;

  List<Product> _products = [];
  List<Category> _categories = [];
  int _totalProducts = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int? _selectedCategoryId;
  String _searchQuery = '';
  String? _error;

  ProductProvider(this._api);

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  int get totalProducts => _totalProducts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get error => _error;

  Future<void> loadCategories() async {
    try {
      final data = await _api.getCategories();
      _categories = data.map((e) => Category.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) notifyListeners();

    try {
      final data = await _api.getProducts(
        page: _currentPage,
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final items = (data['items'] as List<dynamic>)
          .map((e) => Product.fromJson(e))
          .toList();
      _totalProducts = data['total'] ?? 0;

      if (refresh) {
        _products = items;
      } else {
        _products.addAll(items);
      }

      final totalPages = data['total_pages'] ?? 1;
      _hasMore = _currentPage < totalPages;
      _currentPage++;
    } catch (e) {
      debugPrint('Failed to load products: $e');
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  void search(String query) {
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  Future<Product?> getProductDetail(int id) async {
    try {
      final data = await _api.getProductDetail(id);
      return Product.fromJson(data);
    } catch (e) {
      debugPrint('Failed to load product $id: $e');
      return null;
    }
  }
}
