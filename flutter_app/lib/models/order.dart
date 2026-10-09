class OrderItem {
  final int id;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productName: json['product_name'],
      quantity: double.parse(json['quantity'].toString()),
      unitPrice: double.parse(json['unit_price'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
    );
  }
}

class OrderStatusEntry {
  final String status;
  final String? notes;
  final String? createdBy;
  final String createdAt;

  OrderStatusEntry({
    required this.status,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory OrderStatusEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusEntry(
      status: json['status'],
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double gstAmount;
  final double total;
  final String paymentMode;
  final String? deliverySlot;
  final String? notes;
  final String createdAt;
  final List<OrderItem> items;
  final List<OrderStatusEntry> statusHistory;
  final int? itemCount; // for list view

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.gstAmount,
    required this.total,
    required this.paymentMode,
    this.deliverySlot,
    this.notes,
    required this.createdAt,
    this.items = const [],
    this.statusHistory = const [],
    this.itemCount,
  });

  String get statusLabel {
    switch (status) {
      case 'PLACED':
        return 'Order Placed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PACKED':
        return 'Packed';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      subtotal: double.parse((json['subtotal'] ?? '0').toString()),
      deliveryCharge: double.parse((json['delivery_charge'] ?? '0').toString()),
      discount: double.parse((json['discount'] ?? '0').toString()),
      gstAmount: double.parse((json['gst_amount'] ?? '0').toString()),
      total: double.parse((json['total'] ?? '0').toString()),
      paymentMode: json['payment_mode'] ?? 'COD',
      deliverySlot: json['delivery_slot'],
      notes: json['notes'],
      createdAt: json['created_at'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) => OrderStatusEntry.fromJson(e))
              .toList() ??
          [],
      itemCount: json['item_count'],
    );
  }
}
