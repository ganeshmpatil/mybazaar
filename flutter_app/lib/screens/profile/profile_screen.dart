import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      await context.read<AuthProvider>().updateProfile(
            _nameController.text.trim(),
            _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
          );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final user = auth.user;
          if (user == null) return const SizedBox();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.cardBg,
                        child: Text(
                          (user.name ?? user.mobile)[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                      ] else ...[
                        Text(
                          user.name ?? 'Set your name',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: user.name != null
                                ? AppColors.textPrimary
                                : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+91 ${user.mobile}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (user.email != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.email!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Menu items
                _menuCard([
                  _menuItem(Icons.location_on_outlined, 'My Addresses',
                      subtitle: '${auth.addresses.length} saved', onTap: () {
                    auth.loadAddresses();
                  }),
                  _menuItem(Icons.help_outline_rounded, 'Help & Support',
                      onTap: () {}),
                  _menuItem(Icons.info_outline_rounded, 'About MyBazaar',
                      onTap: () {}),
                ]),

                const SizedBox(height: 16),

                _menuCard([
                  _menuItem(Icons.logout_rounded, 'Logout',
                      color: AppColors.error, onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Logout?'),
                        content: const Text(
                            'Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await auth.logout();
                      context.read<CartProvider>().clear();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    }
                  }),
                ]),

                const SizedBox(height: 32),
                Text(
                  'MyBazaar v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _menuItem(IconData icon, String title,
      {String? subtitle, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}
