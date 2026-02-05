import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ This includes kDebugMode
import 'package:http/http.dart' as http;
import '../core/services/auth_service.dart'; // ✅ ADD THIS IMPORT

class ApiService {
  // ⭐ PRODUCTION URL (Render)
  //static const String baseUrl = 'https://agriassist-cxng.onrender.com';
  static const String baseUrl = 'http://10.108.2.174:8000';

  // Store data temporarily for the session (volatile memory)
  static String? currentPhoneNumber;
  static int? currentUserId;

  // ✅ ADD THIS METHOD (Make sure it exists)
  static Future<void> initializeFromStorage() async {
    currentUserId = await AuthService.getUserId();
    currentPhoneNumber = await AuthService.getPhoneNumber();

    if (kDebugMode) {
      print("📱 ApiService initialized from storage:");
      print("   User ID: $currentUserId");
      print("   Phone: $currentPhoneNumber");
    }
  }


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
        currentPhoneNumber = phone;
        return true;
      }
      if (kDebugMode) print("Error Send OTP: ${response.body}");
      return false;
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
        currentUserId = data['user_id'];
        if (kDebugMode) print("User Verified. ID: $currentUserId");
        return true;
      }
      if (kDebugMode) print("Error Verify OTP: ${response.body}");
      return false;
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
      final response = await http.put(url, body: data);
      if (response.statusCode == 200) {
        if (kDebugMode) print("Profile Updated: $data");
        return true;
      }
      if (kDebugMode) print("Error Update Profile: ${response.body}");
      return false;
    } catch (e) {
      if (kDebugMode) print("Exception Update Profile: $e");
      return false;
    }
  }

  // --- 4. Create Chat Session (NEW) ---
  static Future<int?> createSession(String title) async {
    if (currentUserId == null) {
      if (kDebugMode) print("Error: User ID is null. Log in first.");
      return null;
    }

    // user_id is passed as a query parameter
    final url = Uri.parse('$baseUrl/chat/sessions?user_id=$currentUserId');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"title": title}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // Returns the new Session ID
      } else {
        if (kDebugMode) print("Error Create Session: ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Create Session: $e");
      return null;
    }
  }

  // --- 5. Send Message to AI (NEW) ---
  static Future<String?> sendChatMessage(int sessionId, String message) async {
    if (currentUserId == null) return null;

    // Endpoint structure: /chat/{session_id}/message?user_id={user_id}
    final url = Uri.parse('$baseUrl/chat/$sessionId/message?user_id=$currentUserId');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"content": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The backend returns the AI message object. We want the 'content'.
        return data['content'];
      } else {
        if (kDebugMode) print("Error Send Message: ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Send Message: $e");
      return null;
    }
  }


// --- 6. Gemini Text-to-Speech (TTS) ---
  static Future<Uint8List?> generateSpeech(String text) async {
    final url = Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer YOUR_GEMINI_API_KEY", // You need an API key
        },
        body: jsonEncode({
          "input": {"text": text},
          "voice": {
            "languageCode": "en-US",
            "name": "en-US-Neural2-J",
            "ssmlGender": "MALE"
          },
          "audioConfig": {
            "audioEncoding": "MP3",
            "speakingRate": 1.0,
            "pitch": 0.0,
            "volumeGainDb": 0.0
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioContent = data['audioContent'];
        return base64Decode(audioContent);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("Exception TTS: $e");
      return null;
    }
  }
}