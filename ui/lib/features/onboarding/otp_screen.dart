import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/otp_box.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/cloudy_background.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../core/services/auth_service.dart'; // ✅ ADD THIS IMPORT

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  String? _otpError;
  bool _isLoading = false;

  Future<void> _validateOtp() async {
    String otp = _controllers.map((c) => c.text).join();

    if (otp.isEmpty) {
      setState(() => _otpError = "OTP must not be blank");
      return;
    } else if (otp.length < 6) {
      setState(() => _otpError = "6 numeric digits are required");
      return;
    }

    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    bool success = await ApiService.verifyOtp(otp);

    if (success) {
      // ✅ SAVE LOGIN STATUS AND USER DATA
      await AuthService.setLoggedIn(
        true,
        userId: ApiService.currentUserId,
        phoneNumber: ApiService.currentPhoneNumber,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushNamed(context, AppRoutes.personalization);
    } else if (mounted) {
      setState(() => _otpError = "Invalid OTP or Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CloudyBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Text("Enter the OTP sent to\nyour number", style: AppTextStyles.heading),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _controllers.map((c) => OtpBox(controller: c)).toList(),
            ),
            if (_otpError != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Text(_otpError!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(text: "Next →", onTap: _validateOtp),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}