import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../tracking/delivery_tracking_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order =
        await context.read<OrderProvider>().getOrderDetail(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _order!.orderNumber,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  _statusBadge(_order!.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(_order!.createdAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Items
                        _sectionTitle('Items'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: _order!.items.map((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '₹${item.unitPrice.toStringAsFixed(0)} × ${_formatQty(item.quantity)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Price breakdown
                        _sectionTitle('Price Details'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              _priceRow('Subtotal',
                                  '₹${_order!.subtotal.toStringAsFixed(0)}'),
                              _priceRow('Delivery',
                                  _order!.deliveryCharge > 0
                                      ? '₹${_order!.deliveryCharge.toStringAsFixed(0)}'
                                      : 'FREE'),
                              if (_order!.discount > 0)
                                _priceRow('Discount',
                                    '-₹${_order!.discount.toStringAsFixed(0)}',
                                    isDiscount: true),
                              _priceRow('GST',
                                  '₹${_order!.gstAmount.toStringAsFixed(0)}'),
                              const Divider(height: 20),
                              _priceRow('Total',
                                  '₹${_order!.total.toStringAsFixed(0)}',
                                  bold: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Status timeline
                        if (_order!.statusHistory.isNotEmpty) ...[
                          _sectionTitle('Order Timeline'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: _order!.statusHistory
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final i = entry.key;
                                final sh = entry.value;
                                final isLast =
                                    i == _order!.statusHistory.length - 1;
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isLast
                                                ? AppColors.primary
                                                : AppColors.divider,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 40,
                                            color: AppColors.divider,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sh.status,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(sh.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        // Track delivery button
                        if (_order!.status == 'OUT_FOR_DELIVERY') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DeliveryTrackingScreen(
                                      orderId: widget.orderId,
                                      orderNumber: _order!.orderNumber,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.location_on),
                              label: const Text('Track Delivery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Cancel button
                        if (_order!.status == 'PLACED' ||
                            _order!.status == 'CONFIRMED') ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _cancelOrder(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel Order'),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Yes, Cancel', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<OrderProvider>().cancelOrder(widget.orderId);
      await _loadOrder();
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool bold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 18 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: isDiscount
                    ? AppColors.success
                    : bold
                        ? AppColors.primary
                        : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'DELIVERED':
        color = AppColors.success;
      case 'CANCELLED':
        color = AppColors.error;
      case 'OUT_FOR_DELIVERY':
        color = Colors.blue;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _order!.statusLabel,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  String _formatQty(double qty) {
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }
}
