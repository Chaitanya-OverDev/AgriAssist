import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../core/services/auth_service.dart'; // 👈 Import your AuthService

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }

  // Use a function to handle the async check
  void _startNavigationTimer() async {
    // 1. Wait for 2 seconds (for the logo to show)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. Check if the user is already logged in
    bool loggedIn = await AuthService.isLoggedIn();

    // 3. Navigate to the correct screen
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.voiceChat);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.blue[300],
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage("https://via.placeholder.com/150"),
                    fit: BoxFit.cover,
                  )
              ),
              child: const Icon(Icons.agriculture, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "AgriAssist",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}