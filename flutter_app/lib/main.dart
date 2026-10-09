import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyBazaarApp());
}

class MyBazaarApp extends StatelessWidget {
  const MyBazaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ProductProvider(apiService)),
        ChangeNotifierProvider(create: (_) => CartProvider(apiService)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'MyBazaar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
