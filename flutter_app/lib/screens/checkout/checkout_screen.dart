import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../orders/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int? _selectedAddressId;
  String _deliverySlot = 'morning';
  final _notesController = TextEditingController();
  bool _isPlacing = false;
  bool _showAddressForm = false;
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();

  final _deliverySlots = {
    'morning': '9 AM - 12 PM',
    'afternoon': '12 PM - 3 PM',
    'evening': '3 PM - 6 PM',
    'night': '6 PM - 9 PM',
  };

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    auth.loadAddresses().then((_) {
      if (auth.addresses.isNotEmpty && mounted) {
        setState(() {
          _selectedAddressId =
              auth.addresses.firstWhere((a) => a.isDefault, orElse: () => auth.addresses.first).id;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    if (_addressController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    try {
      final address = await auth.addAddress(
        fullAddress: _addressController.text.trim(),
        label: 'Home',
        pincode: _pincodeController.text.trim(),
        city: _cityController.text.trim(),
      );
      setState(() {
        _selectedAddressId = address.id;
        _showAddressForm = false;
      });
      _addressController.clear();
      _pincodeController.clear();
      _cityController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add address: $e')),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address')),
      );
      return;
    }

    setState(() => _isPlacing = true);
    try {
      final order = await context.read<CartProvider>().placeOrder(
            addressId: _selectedAddressId!,
            deliverySlot: _deliverySlot,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: order),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery address
            _sectionTitle('Delivery Address'),
            const SizedBox(height: 8),
            ...auth.addresses.map((addr) => _addressTile(addr)),
            if (auth.addresses.isEmpty && !_showAddressForm)
              _emptyCard(
                'No address added',
                'Add your delivery address',
                Icons.location_on_outlined,
              ),
            const SizedBox(height: 8),

            if (_showAddressForm) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Full address',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(hintText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(hintText: 'Pincode'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _showAddressForm = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addAddress,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              TextButton.icon(
                onPressed: () => setState(() => _showAddressForm = true),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add New Address'),
              ),

            const SizedBox(height: 20),

            // Delivery slot
            _sectionTitle('Delivery Slot'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _deliverySlots.entries.map((entry) {
                final isSelected = _deliverySlot == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _deliverySlot = entry.key),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          entry.key[0].toUpperCase() + entry.key.substring(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Notes
            _sectionTitle('Delivery Notes (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'E.g. Ring the bell twice',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment method
            _sectionTitle('Payment'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.money_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Pay when you receive',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Order summary
            _sectionTitle('Order Summary'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _summaryRow('Subtotal', '₹${cart.total.toStringAsFixed(0)}'),
                  _summaryRow('Delivery', 'FREE'),
                  _summaryRow('GST', 'Included'),
                  const Divider(height: 24),
                  _summaryRow(
                    'Total',
                    '₹${cart.total.toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Place order button
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
              onPressed: _isPlacing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isPlacing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Place Order  •  ₹${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressTile(dynamic addr) {
    final isSelected = _selectedAddressId == addr.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = addr.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (addr.label != null)
                    Text(
                      addr.label!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    addr.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
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

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 18 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? AppColors.primary : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: AppColors.textLight),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
