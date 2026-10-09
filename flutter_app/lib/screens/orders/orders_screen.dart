import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to place your first order',
                    style: TextStyle(fontSize: 14, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadOrders(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              itemBuilder: (_, i) => _orderCard(provider.orders[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(Order order) {
    final date = DateTime.tryParse(order.createdAt);
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal())
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                _statusBadge(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount ?? 0} items',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'PLACED':
      case 'CONFIRMED':
        color = AppColors.warning;
        break;
      case 'OUT_FOR_DELIVERY':
        color = Colors.blue;
        break;
      case 'DELIVERED':
        color = AppColors.success;
        break;
      case 'CANCELLED':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        Order(
          id: 0,
          orderNumber: '',
          status: status,
          subtotal: 0,
          deliveryCharge: 0,
          discount: 0,
          gstAmount: 0,
          total: 0,
          paymentMode: '',
          createdAt: '',
        ).statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
