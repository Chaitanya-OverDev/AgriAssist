import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/app_routes.dart'; // Ensure this path points to your app_routes.dart

class NameScreen extends StatelessWidget {
  const NameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevents the background from shrinking when the keyboard pops up
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Action Area (Language Selector)
            // Height is matched to the back button's CircleAvatar height
            Align(
              alignment: Alignment.topRight,
              child: Container(
                height: 40, // Matches CircleAvatar diameter
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Eng"),
                    Icon(Icons.keyboard_arrow_down, size: 16)
                  ],
                ),
              ),
            ),

            // 2. Exact same gap (40) to maintain heading alignment
            const SizedBox(height: 40),

            // 3. Heading
            const Text("What's your\nname?", style: AppTextStyles.heading),

            const SizedBox(height: 40),

            // 4. Input Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Enter your name", style: AppTextStyles.label),
                  const SizedBox(height: 10),
                  const CustomTextField(
                    hintText: "Prajwal",
                  ),
                ],
              ),
            ),

            // 5. Buttons Pinned to Bottom
            PrimaryButton(
              text: "Submit",
              onTap: () {
                // Navigate to the main voice chat feature after onboarding
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.voiceChat, (route) => false);
              },
            ),

            const SizedBox(height: 15),
            const Center(
              child: Text(
                "Skip for Now",
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500
                ),
              ),
            ),

            // 6. Fixed bottom spacing (Matches other screens)
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}