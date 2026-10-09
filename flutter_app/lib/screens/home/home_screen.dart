import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import 'widgets/product_card.dart';
import 'widgets/category_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MyBazaar',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Delivering near you',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _iconButton(Icons.notifications_none_rounded, () {}),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (q) {
                  context.read<ProductProvider>().search(q);
                },
                decoration: InputDecoration(
                  hintText: 'Search groceries, fruits, oil...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textLight),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProductProvider>().search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Categories
            const CategoryBar(),

            // Products grid
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading && provider.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: AppColors.textLight),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadProducts(refresh: true),
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.products.length +
                          (provider.hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= provider.products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return ProductCard(
                          product: provider.products[i],
                          onAddToCart: (product, qty) {
                            context
                                .read<CartProvider>()
                                .addToCart(product.id, qty);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}
