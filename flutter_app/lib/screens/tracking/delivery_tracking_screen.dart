import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();

  // Store location (Aurangabad area)
  static const _storeLocation = LatLng(19.876, 75.343);

  LatLng? _deliveryBoyLocation;
  List<LatLng> _routePoints = [];
  String _status = 'Loading...';
  String _deliveryBoyName = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    // Poll every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchLocation());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final token = await _api.token;
      if (token == null) return;

      // Get live location
      final locRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/tracking/location/${widget.orderId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (locRes.statusCode == 200) {
        final data = jsonDecode(locRes.body);
        if (data['latitude'] != null) {
          setState(() {
            _deliveryBoyLocation = LatLng(
              (data['latitude'] as num).toDouble(),
              (data['longitude'] as num).toDouble(),
            );
            _deliveryBoyName = data['delivery_boy_name'] ?? 'Delivery Partner';
            _status = 'On the way';
          });
        } else {
          setState(() => _status = 'Waiting for location update...');
        }
      }

      // Get route history
      final routeRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/tracking/route/${widget.orderId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (routeRes.statusCode == 200) {
        final points = jsonDecode(routeRes.body) as List;
        setState(() {
          _routePoints = points
              .map((p) => LatLng(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                  ))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Tracking error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${widget.orderNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
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

              // Route polyline
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

              // Markers
              MarkerLayer(
                markers: [
                  // Store marker
                  Marker(
                    point: _storeLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 20),
                    ),
                  ),

                  // Delivery boy marker
                  if (_deliveryBoyLocation != null)
                    Marker(
                      point: _deliveryBoyLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Bottom info card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _deliveryBoyName.isNotEmpty ? _deliveryBoyName : 'Delivery Partner',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _deliveryBoyLocation != null ? Colors.green : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _status,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_deliveryBoyLocation != null)
                        IconButton(
                          onPressed: () {
                            _mapController.move(_deliveryBoyLocation!, 16);
                          },
                          icon: const Icon(Icons.my_location, color: Colors.blue),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
