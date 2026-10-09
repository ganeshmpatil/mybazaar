class Category {
  final int id;
  final String name;
  final int? parentId;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class ProductVariant {
  final String label; // "1 KG", "5 KG", "500 ml"
  final double price;
  final int? productId; // if variant is a separate product

  ProductVariant({
    required this.label,
    required this.price,
    this.productId,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      label: json['label'],
      price: double.parse(json['price'].toString()),
      productId: json['product_id'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? description;
  final int? categoryId;
  final double mrp;
  final double sellingPrice;
  final String? unit;
  final String? primaryImage;
  final double? stockQuantity;
  final bool isActive;
  final double? gstPercent;
  final Map<String, dynamic>? attributes;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    required this.mrp,
    required this.sellingPrice,
    this.unit,
    this.primaryImage,
    this.stockQuantity,
    required this.isActive,
    this.gstPercent,
    this.attributes,
    this.images = const [],
  });

  bool get inStock => (stockQuantity ?? 0) > 0;

  double get discountPercent {
    if (mrp <= 0) return 0;
    return ((mrp - sellingPrice) / mrp * 100);
  }

  bool get hasDiscount => mrp > sellingPrice;

  /// Weight presets based on unit type
  List<String> get weightPresets {
    final unit = this.unit?.toLowerCase() ?? '';
    if (unit == 'kg') return ['500 g', '1 KG', '2 KG', '5 KG'];
    if (unit == 'l' || unit == 'litre') return ['500 ml', '1 L', '2 L', '5 L', '10 L'];
    if (unit == 'g') return ['100 g', '250 g', '500 g', '1 KG'];
    if (unit == 'ml') return ['100 ml', '250 ml', '500 ml', '1 L'];
    return []; // For 'pcs' or other units, use simple quantity
  }

  /// Convert a weight preset label to a numeric quantity
  double presetToQuantity(String preset) {
    final unit = this.unit?.toLowerCase() ?? '';
    final lower = preset.toLowerCase().trim();

    if (unit == 'kg') {
      if (lower.endsWith('g')) {
        final grams = double.tryParse(lower.replaceAll('g', '').trim()) ?? 0;
        return grams / 1000;
      }
      final kg = double.tryParse(lower.replaceAll('kg', '').trim()) ?? 1;
      return kg;
    }

    if (unit == 'l' || unit == 'litre') {
      if (lower.endsWith('ml')) {
        final ml = double.tryParse(lower.replaceAll('ml', '').trim()) ?? 0;
        return ml / 1000;
      }
      final l = double.tryParse(lower.replaceAll('l', '').trim()) ?? 1;
      return l;
    }

    if (unit == 'g') {
      if (lower.endsWith('kg')) {
        final kg = double.tryParse(lower.replaceAll('kg', '').trim()) ?? 0;
        return kg * 1000;
      }
      return double.tryParse(lower.replaceAll('g', '').trim()) ?? 1;
    }

    if (unit == 'ml') {
      if (lower.endsWith('l') && !lower.endsWith('ml')) {
        final l = double.tryParse(lower.replaceAll('l', '').trim()) ?? 0;
        return l * 1000;
      }
      return double.tryParse(lower.replaceAll('ml', '').trim()) ?? 1;
    }

    return double.tryParse(lower) ?? 1;
  }

  String get unitLabel {
    final u = unit?.toLowerCase() ?? 'pcs';
    switch (u) {
      case 'kg':
        return 'per KG';
      case 'l':
      case 'litre':
        return 'per L';
      case 'g':
        return 'per 100g';
      case 'ml':
        return 'per 100ml';
      default:
        return 'each';
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      categoryId: json['category_id'],
      mrp: double.parse((json['mrp'] ?? '0').toString()),
      sellingPrice: double.parse((json['selling_price'] ?? '0').toString()),
      unit: json['unit'],
      primaryImage: json['primary_image'],
      stockQuantity: json['stock_quantity'] != null
          ? double.parse(json['stock_quantity'].toString())
          : null,
      isActive: json['is_active'] ?? true,
      gstPercent: json['gst_percent'] != null
          ? double.parse(json['gst_percent'].toString())
          : null,
      attributes: json['attributes'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ProductImage {
  final int id;
  final String imageUrl;
  final int sortOrder;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
    required this.isPrimary,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'] ?? 0,
      isPrimary: json['is_primary'] ?? false,
    );
  }
}
