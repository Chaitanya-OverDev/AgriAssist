import 'package:flutter/material.dart';
// Import the sherpa package to access initBindings
import 'package:sherpa_onnx/sherpa_onnx.dart'; 
import 'routes/app_routes.dart';
import 'services/api_service.dart';
// Import your audio service file
import './core/services/chat_audio_service.dart'; 

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Sherpa ONNX native bindings (CRITICAL for voice)
  // This must be called only once and before the app starts to prevent crashes.
  initBindings();

  // 3. Initialize ApiService with stored user data
  await ApiService.initializeFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriAssist',
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}