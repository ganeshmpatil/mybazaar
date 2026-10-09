import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/variant_selector.dart';
import '../../widgets/quantity_stepper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _selectedVariant;
  double _quantity = 1;
  bool _addedToCart = false;

  @override
  void initState() {
    super.initState();
    final presets = widget.product.weightPresets;
    if (presets.isNotEmpty) {
      // Default to the second option (typically "1 KG" or "1 L")
      _selectedVariant = presets.length > 1 ? presets[1] : presets[0];
      _quantity = widget.product.presetToQuantity(_selectedVariant);
    }
  }

  bool get _hasVariants => widget.product.weightPresets.isNotEmpty;

  double get _totalPrice => widget.product.sellingPrice * _quantity;

  Future<void> _addToCart() async {
    await context.read<CartProvider>().addToCart(widget.product.id, _quantity);
    if (!mounted) return;
    setState(() => _addedToCart = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _addedToCart = false);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.cardBg,
            leading: _circleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _circleButton(
                icon: Icons.shopping_cart_outlined,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.primaryImage != null
                  ? CachedNetworkImage(
                      imageUrl: product.primaryImage!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and stock status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: product.inStock
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.inStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.inStock
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${product.sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.unit != null) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '/${product.unit}',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '₹${product.mrp.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textLight,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.discount,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.discountPercent.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Weight / Size Selector ──
                    if (_hasVariants) ...[
                      const Text(
                        'Select Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      VariantSelector(
                        options: product.weightPresets,
                        selected: _selectedVariant,
                        onSelected: (variant) {
                          setState(() {
                            _selectedVariant = variant;
                            _quantity =
                                product.presetToQuantity(variant);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Show calculated total
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$_selectedVariant × ₹${product.sellingPrice.toStringAsFixed(0)}/${product.unit}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${_totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Simple quantity selector for "pcs" items
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          QuantityStepper(
                            quantity: _quantity,
                            onChanged: (q) => setState(() => _quantity = q),
                            unit: product.unit,
                          ),
                          const Spacer(),
                          Text(
                            '₹${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Description
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Product info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (product.gstPercent != null)
                          _infoChip('GST: ${product.gstPercent!.toStringAsFixed(0)}%'),
                        _infoChip('Payment: Cash on Delivery'),
                        _infoChip('Delivery: Same Day'),
                      ],
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Add to Cart button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: product.inStock && !_addedToCart ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _addedToCart ? AppColors.success : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _addedToCart
                        ? Icons.check_circle_rounded
                        : Icons.shopping_cart_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _addedToCart
                        ? 'Added to Cart!'
                        : 'Add to Cart  •  ₹${_totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 80,
        color: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _circleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
