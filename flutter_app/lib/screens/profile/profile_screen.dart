import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/strings.dart';
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
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('profile')),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: Text(tr('edit_profile')),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(tr('save')),
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
                          decoration: InputDecoration(
                            labelText: tr('name'),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: tr('email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                      ] else ...[
                        Text(
                          user.name ?? tr('name'),
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

                // Language toggle
                _menuCard([
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: AppColors.textPrimary),
                    title: Text(
                      tr('language'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _langChip('EN', AppLanguage.en, langProvider),
                          const SizedBox(width: 2),
                          _langChip('मराठी', AppLanguage.mr, langProvider),
                        ],
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // Menu items
                _menuCard([
                  _menuItem(Icons.location_on_outlined, 'My Addresses',
                      subtitle: '${auth.addresses.length} saved', onTap: () {
                    auth.loadAddresses();
                  }),
                  _menuItem(Icons.help_outline_rounded, 'Help & Support',
                      onTap: () {}),
                ]),

                const SizedBox(height: 16),

                _menuCard([
                  _menuItem(Icons.logout_rounded, tr('logout'),
                      color: AppColors.error, onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(tr('logout')),
                        content: const Text(
                            'Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(tr('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(tr('logout'),
                                style: const TextStyle(color: AppColors.error)),
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
                  '${tr('app_name')} v1.0.0',
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

  Widget _langChip(String label, AppLanguage lang, LanguageProvider provider) {
    final isActive = provider.language == lang;
    return GestureDetector(
      onTap: () => provider.setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
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
