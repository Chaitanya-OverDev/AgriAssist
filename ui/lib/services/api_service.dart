import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 'localhost' for iOS Simulator
  // If using a physical device, use your PC's IP address (e.g., http://192.168.1.5:8000)
  static const String baseUrl = 'https://agriassist-cxng.onrender.com';

  // Store data temporarily for the session
  static String? currentPhoneNumber;
  static int? currentUserId;

  // --- 1. Send OTP ---
  static Future<bool> sendOtp(String phone) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');

    try {
      if (kDebugMode) print("Sending OTP to: $phone");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": phone}),
      );

      if (response.statusCode == 200) {
        currentPhoneNumber = phone; // Store phone for the next step
        return true;
      } else {
        if (kDebugMode) print("Error Send OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Send OTP: $e");
      return false;
    }
  }

  // --- 2. Verify OTP ---
  static Future<bool> verifyOtp(String otp) async {
    if (currentPhoneNumber == null) return false;

    final url = Uri.parse('$baseUrl/auth/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": currentPhoneNumber,
          "otp": otp
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['user_id']; // Store User ID for profile updates
        if (kDebugMode) print("User Verified. ID: $currentUserId");
        return true;
      } else {
        if (kDebugMode) print("Error Verify OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Verify OTP: $e");
      return false;
    }
  }

  // --- 3. Update User Profile ---
  static Future<bool> updateUserProfile(Map<String, String> data) async {
    if (currentUserId == null) return false;

    final url = Uri.parse('$baseUrl/users/update/$currentUserId');

    try {
      // Your backend expects Form Data (application/x-www-form-urlencoded) for updates
      // based on: full_name: str = Form(None) in main.py
      final response = await http.put(
        url,
        body: data,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print("Profile Updated: $data");
        return true;
      } else {
        if (kDebugMode) print("Error Update Profile: ${response.body}");
        return false;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Update Profile: $e");
      return false;
    }
  }
}