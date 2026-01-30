import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/cloudy_background.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _errorMessage;

  void _validateAndSubmit() {
    final value = _phoneController.text.trim(); // Trim white spaces

    setState(() {
      if (value.isEmpty) {
        _errorMessage = "It must not be blank";
      } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        _errorMessage = "Only numeric values are allowed";
      } else if (!RegExp(r'^[6-9]').hasMatch(value)) {
        _errorMessage = "Please enter a valid number";
      } else if (value.length != 10) {
        _errorMessage = "Must be a 10 digit number";
      } else {
        _errorMessage = null;
        ApiService.submitOnboardingData({"phone": value});
        Navigator.pushNamed(context, AppRoutes.otp);
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
            const Text("Verify your\nPhone Number", style: AppTextStyles.heading),
            const SizedBox(height: 40),
            const Text("Enter the phone number", style: AppTextStyles.label),
            const SizedBox(height: 10),
            CustomTextField(
              hintText: "1234567890",
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              errorText: _errorMessage, // Display exact msg below textbox
            ),
            const Spacer(),
            PrimaryButton(text: "Get OTP", onTap: _validateAndSubmit),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}