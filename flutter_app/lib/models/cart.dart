class CartItem {
  final int id;
  final int productId;
  final String productName;
  final double sellingPrice;
  final double quantity;
  final double subtotal;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      sellingPrice: double.parse(json['selling_price'].toString()),
      quantity: double.parse(json['quantity'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class Cart {
  final List<CartItem> items;
  final double total;
  final int itemCount;

  Cart({
    required this.items,
    required this.total,
    required this.itemCount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e))
          .toList(),
      total: double.parse(json['total'].toString()),
      itemCount: json['item_count'],
    );
  }
}
