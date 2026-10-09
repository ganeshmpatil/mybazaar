import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/strings.dart';
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'cart/cart_screen.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts(refresh: true);
      context.read<ProductProvider>().loadFilters();
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              activeIcon: const Icon(Icons.home_rounded),
              label: tr('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: _buildCartIcon(false),
              activeIcon: _buildCartIcon(true),
              label: tr('nav_cart'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: tr('nav_orders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: tr('nav_profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartIcon(bool active) {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        return Badge(
          isLabelVisible: cart.itemCount > 0,
          label: Text(
            cart.itemCount.toString(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: AppColors.accent,
          child: Icon(
            active ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
          ),
        );
      },
    );
  }
}
