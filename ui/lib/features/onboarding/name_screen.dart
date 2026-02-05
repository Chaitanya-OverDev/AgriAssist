import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/cloudy_background.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../core/services/auth_service.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitName() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = "Name is required to continue";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Update Profile on Backend
      await ApiService.updateUserProfile({"full_name": name});

      // 2. Remember the user locally
      await AuthService.setLoggedIn(true);

      if (mounted) {
        // 3. Clear the whole stack and go to Voice Chat
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.voiceChat,
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            const Text("What's your\nname?", style: AppTextStyles.heading),
            const SizedBox(height: 40),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: "Enter your name",
                      style: AppTextStyles.label,
                      children: [
                        TextSpan(
                            text: " *",
                            style: TextStyle(color: Colors.red)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cleaned up CustomTextField to match your widget definition
                  CustomTextField(
                    hintText: "Full Name",
                    controller: _nameController,
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0E3D3D)))
                : PrimaryButton(
              text: "Submit",
              onTap: _submitName,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}