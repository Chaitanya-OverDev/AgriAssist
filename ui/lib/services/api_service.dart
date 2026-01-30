import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  static Future<void> submitOnboardingData(Map<String, dynamic> data) async {
    // Show data entered by the user on console
    if (kDebugMode) {
      print("Sending Data to Backend: ${jsonEncode(data)}");
    }
    // Implement endpoint connection here
  }
}