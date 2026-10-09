import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/product_provider.dart';

class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key});

  static const _categoryIcons = {
    'groceries': Icons.local_grocery_store_rounded,
    'fruits': Icons.apple_rounded,
    'vegetables': Icons.eco_rounded,
    'dairy': Icons.egg_rounded,
    'snacks': Icons.cookie_rounded,
    'beverages': Icons.local_cafe_rounded,
    'personal care': Icons.sanitizer_rounded,
    'household': Icons.home_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (_, provider, __) {
        final categories = provider.categories;
        final selected = provider.selectedCategoryId;

        return SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // +1 for "All"
            itemBuilder: (_, i) {
              if (i == 0) {
                return _chip(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  isSelected: selected == null,
                  onTap: () => provider.selectCategory(null),
                );
              }
              final cat = categories[i - 1];
              final icon = _categoryIcons[cat.name.toLowerCase()] ??
                  Icons.category_rounded;
              return _chip(
                label: cat.name,
                icon: icon,
                isSelected: selected == cat.id,
                onTap: () => provider.selectCategory(cat.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
