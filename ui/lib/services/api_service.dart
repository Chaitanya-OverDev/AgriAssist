import 'dart:convert';
import 'dart:typed_data'; // ✅ Required for Uint8List
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/services/auth_service.dart';

class ApiService {
  // ⭐ PRODUCTION URL (Render)
   static const String baseUrl = 'https://agriassist-cxng.onrender.com';
  // static const String baseUrl= 'http://10.0.2.2:8000';
   // static const String baseUrl= 'http://10.61.83.174:8000';


  // Store data temporarily
  static String? currentPhoneNumber;
  static int? currentUserId;

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

  // --- 4. Create Chat Session ---
  static Future<int?> createSession(String title) async {
    if (currentUserId == null) {
      if (kDebugMode) print("Error: User ID is null. Log in first.");
      return null;
    }

    final url = Uri.parse('$baseUrl/chat/sessions?user_id=$currentUserId');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"title": title}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        if (kDebugMode) print("Error Create Session: ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Create Session: $e");
      return null;
    }
  }

  // --- 5. Send Message to AI (UPDATED) ---
  static Future<Map<String, dynamic>?> sendChatMessage(int sessionId, String message) async {
    if (currentUserId == null) return null;

    final url = Uri.parse('$baseUrl/chat/$sessionId/message?user_id=$currentUserId');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"content": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Return both ID and Content
        return {
          'id': data['id'],
          'content': data['content']
        };
      } else {
        if (kDebugMode) print("Error Send Message: ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Send Message: $e");
      return null;
    }
  }

  // --- 6. Get TTS Audio from Backend ---
  static Future<Uint8List?> getTtsAudio(int messageId) async {
    if (currentUserId == null) return null;

    // Call your FastAPI endpoint
    final url = Uri.parse('$baseUrl/chat/message/$messageId/tts?user_id=$currentUserId');

    try {
      if (kDebugMode) print("🔊 Requesting TTS for Message ID: $messageId");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        if (kDebugMode) print("❌ TTS Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("❌ TTS Exception: $e");
      return null;
    }
  }

  // --- 7. Get User Sessions ---
  static Future<List<dynamic>?> getUserSessions() async {
    if (currentUserId == null) {
      if (kDebugMode) print("Error: User ID is null. Log in first.");
      return null;
    }

    final url = Uri.parse('$baseUrl/chat/sessions/$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) print("Error Fetching Sessions: ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Fetching Sessions: $e");
      return null;
    }
  }

  // --- 8. Delete Chat Session ---
  static Future<bool> deleteChatSession(int sessionId) async {
    if (currentUserId == null) return false;

    // Notice we pass user_id as a query parameter as defined in your FastAPI endpoint
    final url = Uri.parse('$baseUrl/chat/sessions/$sessionId?user_id=$currentUserId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (kDebugMode) print("Session $sessionId deleted successfully.");
        return true;
      } else {
        if (kDebugMode) print("Error Deleting Session: ${response.body}");
        return false;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Deleting Session: $e");
      return false;
    }
  }

  // --- 9. Get Message History ---
  static Future<List<Map<String, dynamic>>?> getChatHistory(int sessionId) async {
    if (currentUserId == null) return null;

    final url = Uri.parse('$baseUrl/chat/$sessionId/history?user_id=$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Map the backend schema to the format TextChatScreen expects
        return data.map((msg) {
          return {
            "id": msg["id"],
            // Ensure the role matches what your UI expects ("user" or "bot")
            // If your backend uses "assistant", map it to "bot"
            "role": msg["role"] == "user" ? "user" : "bot",
            "text": msg["content"], // UI expects "text", backend sends "content"
          };
        }).toList();
      } else {
        if (kDebugMode) print("Error Fetching History: ${response.body}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("Exception Fetching History: $e");
      return null;
    }
  }
}