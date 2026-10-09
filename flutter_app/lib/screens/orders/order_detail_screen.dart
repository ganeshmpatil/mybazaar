import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;

  // Live tracking state
  static const _storeLocation = LatLng(21.0191, 75.3575);
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();
  LatLng? _deliveryBoyLocation;
  List<LatLng> _routePoints = [];
  String _deliveryBoyName = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    _fetchLocation();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchLocation());
  }

  Future<void> _fetchLocation() async {
    try {
      final token = await _api.token;
      if (token == null) return;

      final locRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/tracking/location/${widget.orderId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (locRes.statusCode == 200) {
        final data = jsonDecode(locRes.body);
        if (data['latitude'] != null && mounted) {
          setState(() {
            _deliveryBoyLocation = LatLng(
              (data['latitude'] as num).toDouble(),
              (data['longitude'] as num).toDouble(),
            );
            _deliveryBoyName = data['delivery_boy_name'] ?? 'Delivery Partner';
          });
        }
      }

      final routeRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/tracking/route/${widget.orderId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (routeRes.statusCode == 200) {
        final points = jsonDecode(routeRes.body) as List;
        if (mounted) {
          setState(() {
            _routePoints = points
                .map((p) => LatLng(
                      (p['lat'] as num).toDouble(),
                      (p['lng'] as num).toDouble(),
                    ))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Tracking error: $e');
    }
  }

  Future<void> _loadOrder() async {
    final order =
        await context.read<OrderProvider>().getOrderDetail(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
      if (order != null && order.status == 'OUT_FOR_DELIVERY') {
        _startTracking();
      }
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

                        // Live tracking map
                        if (_order!.status == 'OUT_FOR_DELIVERY') ...[
                          const SizedBox(height: 16),
                          _sectionTitle('Live Tracking'),
                          const SizedBox(height: 8),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _deliveryBoyLocation ?? _storeLocation,
                                    initialZoom: 14,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.mybazaar.app',
                                    ),
                                    if (_routePoints.length > 1)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: _routePoints,
                                            strokeWidth: 4,
                                            color: Colors.blue.withValues(alpha: 0.7),
                                          ),
                                        ],
                                      ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _storeLocation,
                                          width: 36,
                                          height: 36,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.store, color: Colors.white, size: 18),
                                          ),
                                        ),
                                        if (_deliveryBoyLocation != null)
                                          Marker(
                                            point: _deliveryBoyLocation!,
                                            width: 36,
                                            height: 36,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.delivery_dining, color: Colors.white, size: 18),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Delivery boy info overlay
                                if (_deliveryBoyLocation != null)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.delivery_dining, color: Colors.blue, size: 18),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _deliveryBoyName.isNotEmpty ? _deliveryBoyName : 'Delivery Partner',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                          ),
                                          Text(
                                            'On the way',
                                            style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Recenter button
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      final center = _deliveryBoyLocation ?? _storeLocation;
                                      _mapController.move(center, 15);
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.my_location, size: 20, color: Colors.blue),
                                    ),
                                  ),
                                ),
                              ],
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
