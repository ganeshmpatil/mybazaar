import 'package:flutter/material.dart';
import '../config/theme.dart';

class QuantityStepper extends StatelessWidget {
  final double quantity;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String? unit;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.step = 1,
    this.min = 1,
    this.max = 99,
    this.unit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayQty = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    final label = unit != null ? '$displayQty $unit' : displayQty;

    if (compact) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(Icons.remove, () {
              if (quantity > min) onChanged(quantity - step);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            _buildButton(Icons.add, () {
              if (quantity < max) onChanged(quantity + step);
            }),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLargeButton(Icons.remove, () {
            if (quantity > min) onChanged(quantity - step);
          }),
          Container(
            constraints: const BoxConstraints(minWidth: 50),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildLargeButton(Icons.add, () {
            if (quantity < max) onChanged(quantity + step);
          }),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildLargeButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}
