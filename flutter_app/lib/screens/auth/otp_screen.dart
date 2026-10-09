import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  const OtpScreen({super.key, required this.mobile});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 4) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().verifyOtp(widget.mobile, otp);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Please try again.');
      _otpController.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await context.read<AuthProvider>().sendOtp(widget.mobile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent again')),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify OTP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 4-digit code sent to\n+91 ${widget.mobile}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Pinput(
                controller: _otpController,
                length: 4,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                onCompleted: _verifyOtp,
                autofocus: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _verifyOtp(_otpController.text),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Verify', style: TextStyle(fontSize: 17)),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _resendOtp,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
