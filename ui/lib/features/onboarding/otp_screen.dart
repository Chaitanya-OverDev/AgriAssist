import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/otp_box.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/cloudy_background.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  String? _otpError;

  void _validateOtp() {
    // Combine all controller values to get the full OTP
    String otp = _controllers.map((c) => c.text).join();

    setState(() {
      if (otp.isEmpty) {
        _otpError = "OTP must not be blank";
      } else if (otp.length < 6 || !RegExp(r'^[0-9]+$').hasMatch(otp)) {
        _otpError = "6 numeric digits are required";
      } else if (otp == "000000") {
        _otpError = "invalid otp";
      } else {
        _otpError = null;
        ApiService.submitOnboardingData({"otp": otp});
        Navigator.pushNamed(context, AppRoutes.personalization);
      }
    });
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
            const Text("Enter the OTP", style: AppTextStyles.heading),
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
            PrimaryButton(text: "Next →", onTap: _validateOtp),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}