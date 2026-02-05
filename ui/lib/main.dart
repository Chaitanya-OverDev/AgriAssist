import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  // We no longer need async here because the Splash Screen
  // will handle the AuthService check while the logo is showing.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriAssist',
      // Always start at Splash. The logic inside splash_screen.dart
      // will now handle the redirect to VoiceChat or Phone.
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}