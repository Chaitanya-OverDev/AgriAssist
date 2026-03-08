import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

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