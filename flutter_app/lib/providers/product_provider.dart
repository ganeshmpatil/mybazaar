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

  // Filters
  Map<String, List<String>> _availableFilters = {};
  Map<String, String> _activeFilters = {};

  ProductProvider(this._api);

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  int get totalProducts => _totalProducts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get error => _error;
  Map<String, List<String>> get availableFilters => _availableFilters;
  Map<String, String> get activeFilters => _activeFilters;
  bool get hasActiveFilters => _activeFilters.isNotEmpty;

  Future<void> loadCategories() async {
    try {
      final data = await _api.getCategories();
      _categories = data.map((e) => Category.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> loadFilters() async {
    try {
      final data = await _api.getFilters(
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final raw = data['filters'] as Map<String, dynamic>? ?? {};
      _availableFilters = raw.map(
        (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
      );
      // Remove active filters that no longer apply
      _activeFilters.removeWhere((k, _) => !_availableFilters.containsKey(k));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load filters: $e');
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
        filters: _activeFilters.isNotEmpty ? _activeFilters : null,
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
    _activeFilters.clear();
    loadFilters();
    loadProducts(refresh: true);
  }

  void search(String query) {
    _searchQuery = query;
    _activeFilters.clear();
    loadFilters();
    loadProducts(refresh: true);
  }

  void setFilter(String key, String value) {
    _activeFilters[key] = value;
    loadProducts(refresh: true);
  }

  void removeFilter(String key) {
    _activeFilters.remove(key);
    loadProducts(refresh: true);
  }

  void clearFilters() {
    _activeFilters.clear();
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
