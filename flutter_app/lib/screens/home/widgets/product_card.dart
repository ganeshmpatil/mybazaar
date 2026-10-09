import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../product/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product product, double quantity) onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: product.primaryImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: product.primaryImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  _placeholderIcon(),
                              errorWidget: (_, __, ___) =>
                                  _placeholderIcon(),
                            ),
                          )
                        : _placeholderIcon(),
                  ),
                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.discount,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Unit badge
                  if (product.unit != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          product.unitLabel,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Price row
                    Row(
                      children: [
                        Text(
                          '₹${product.sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${product.mrp.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: product.inStock
                          ? ElevatedButton(
                              onPressed: () => onAddToCart(product, 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 40,
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}
