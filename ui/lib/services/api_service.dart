import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⭐ PRODUCTION URL (Render)
  static const String baseUrl = 'https://agriassistback.onrender.com';
  // static const String baseUrl= 'http://10.0.2.2:8000'; // For emulator
  // static const String baseUrl= 'http://10.243.19.128:8000'; // For local device

  static String? currentPhoneNumber;
  static int? currentUserId;
  static List<dynamic> localSchemes = [];

  static Map<String, dynamic>? _cachedWeather;
  static Map<String, dynamic>? _cachedMarketData;

  static Future<void> initializeFromStorage() async {
    currentUserId = await AuthService.getUserId();
    currentPhoneNumber = await AuthService.getPhoneNumber();

    if (kDebugMode) {
      print("📱 ApiService initialized from storage:");
      print("   User ID: $currentUserId");
      print("   Phone: $currentPhoneNumber");
    }
  }

  /// Ensures that currentUserId is loaded before any API call that needs it.
  static Future<void> _ensureInitialized() async {
    if (currentUserId == null) {
      await initializeFromStorage();
    }
  }

  // --- 1. Send OTP ---
  static Future<bool> sendOtp(String phone) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": phone}),
      );

      if (response.statusCode == 200) {
        currentPhoneNumber = phone;
        return true;
      }
      if (kDebugMode) print("❌ sendOtp failed: ${response.statusCode}");
      return false;
    } catch (e) {
      if (kDebugMode) print("❌ sendOtp error: $e");
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
        return true;
      }
      if (kDebugMode) print("❌ verifyOtp failed: ${response.statusCode}");
      return false;
    } catch (e) {
      if (kDebugMode) print("❌ verifyOtp error: $e");
      return false;
    }
  }

  // --- 3. Update User Profile ---
  static Future<bool> updateUserProfile(Map<String, String> data) async {
    await _ensureInitialized();
    if (currentUserId == null) return false;

    final url = Uri.parse('$baseUrl/users/update/$currentUserId');

    try {
      final response = await http.put(url, body: data);

      if (response.statusCode == 200) {
        return true;
      }
      if (kDebugMode) print("❌ updateUserProfile failed: ${response.statusCode}");
      return false;
    } catch (e) {
      if (kDebugMode) print("❌ updateUserProfile error: $e");
      return false;
    }
  }

  // --- 4. Create Chat Session ---
  static Future<int?> createSession(String title) async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

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
      }
      if (kDebugMode) print("❌ createSession failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ createSession error: $e");
      return null;
    }
  }

// --- 5. Send Chat Message ---
  static Future<Map<String, dynamic>?> sendChatMessage(
      int sessionId, String message,
      {bool isVoiceMode = false}) async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    // Grab language from SharedPreferences (Default to Marathi)
    final prefs = await SharedPreferences.getInstance();
    String currentLanguage = prefs.getString('selected_lang_name') ?? 'मराठी (Marathi)';

    final url =
    Uri.parse('$baseUrl/chat/$sessionId/message?user_id=$currentUserId');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "content": message,
          "is_voice_mode": isVoiceMode,
          "language": currentLanguage, // Send language to the backend
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'id': data['id'],
          'content': data['content']
        };
      }
      if (kDebugMode) print("❌ sendChatMessage failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ sendChatMessage error: $e");
      return null;
    }
  }

  // --- 6. Get TTS Audio (Updated for On-Demand Edge TTS) ---
  static Future<Uint8List?> getTtsAudio(int messageId) async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    final url = Uri.parse('$baseUrl/chat/message/$messageId/audio');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        if (kDebugMode) print("❌ getTtsAudio failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("❌ getTtsAudio error: $e");
      return null;
    }
  }

  // --- 7. Get User Sessions ---
  static Future<List<dynamic>?> getUserSessions() async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    final url = Uri.parse('$baseUrl/chat/sessions/$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (kDebugMode) print("❌ getUserSessions failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ getUserSessions error: $e");
      return null;
    }
  }

  // --- 8. Delete Chat Session ---
  static Future<bool> deleteChatSession(int sessionId) async {
    await _ensureInitialized();
    if (currentUserId == null) return false;

    final url =
    Uri.parse('$baseUrl/chat/sessions/$sessionId?user_id=$currentUserId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) return true;
      if (kDebugMode) print("❌ deleteChatSession failed: ${response.statusCode}");
      return false;
    } catch (e) {
      if (kDebugMode) print("❌ deleteChatSession error: $e");
      return false;
    }
  }

  // --- 9. Get Chat History ---
  static Future<List<Map<String, dynamic>>?> getChatHistory(
      int sessionId) async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    final url =
    Uri.parse('$baseUrl/chat/$sessionId/history?user_id=$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((msg) {
          return {
            "id": msg["id"],
            "role": msg["role"] == "user" ? "user" : "bot",
            "text": msg["content"],
          };
        }).toList();
      }
      if (kDebugMode) print("❌ getChatHistory failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ getChatHistory error: $e");
      return null;
    }
  }

  // --- 10. Update User Location ---
  static Future<bool> updateUserLocation(double lat, double lon) async {
    await _ensureInitialized();
    if (currentUserId == null) return false;

    final url = Uri.parse('$baseUrl/users/$currentUserId/location');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": lat,
          "longitude": lon
        }),
      );

      if (response.statusCode == 200) return true;
      if (kDebugMode) print("❌ updateUserLocation failed: ${response.statusCode}");
      return false;
    } catch (e) {
      if (kDebugMode) print("❌ updateUserLocation error: $e");
      return false;
    }
  }

  // --- 11. Get Weather Forecast ---
  static Future<Map<String, dynamic>?> getWeatherForecast(
      {bool forceRefresh = false}) async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    if (!forceRefresh && _cachedWeather != null) {
      return _cachedWeather;
    }

    final url = Uri.parse('$baseUrl/weather/my-forecast/$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        _cachedWeather = jsonDecode(response.body);
        return _cachedWeather;
      }
      if (kDebugMode) print("❌ getWeatherForecast failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ getWeatherForecast error: $e");
      return null;
    }
  }

  // --- 12. Get State Market Data ---
  static Future<Map<String, dynamic>?> getMarketData(
      {bool forceRefresh = false}) async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    if (!forceRefresh && _cachedMarketData != null) {
      return _cachedMarketData;
    }

    final url = Uri.parse('$baseUrl/market/my-state/$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _cachedMarketData = decoded;
        if (kDebugMode) {
          print("Market API Response: $decoded");
        }
        return decoded;
      }
      if (kDebugMode) print("❌ getMarketData failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Market API Error: $e");
      }
      return null;
    }
  }

  // --- 13. Get District Bhavs ---
  static Future<Map<String, dynamic>?> getMyDistrictBhavs() async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    final url = Uri.parse('$baseUrl/market/my-district/$currentUserId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (kDebugMode) print("❌ getMyDistrictBhavs failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ getMyDistrictBhavs error: $e");
      return null;
    }
  }

  // --- 14. Search by State and District ---
  static Future<Map<String, dynamic>?> searchMarketByDistrict(
      String state, String district) async {

    final url = Uri.parse(
        '$baseUrl/market/search?state=$state&district=$district');

    try {
      if (kDebugMode) {
        print("MARKET SEARCH URL: $url");
      }

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (kDebugMode) {
        print("❌ searchMarketByDistrict failed: ${response.statusCode}");
        print("Response body: ${response.body}");
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print("❌ searchMarketByDistrict error: $e");
      }
      return null;
    }
  }

  // --- 15. Search by State Only (no user ID needed) ---
  static Future<Map<String, dynamic>?> searchMarketByState(
      String state) async {
    final url = Uri.parse('$baseUrl/market/search/state?state=$state');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (kDebugMode) print("❌ searchMarketByState failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ searchMarketByState error: $e");
      return null;
    }
  }

  // --- 16. Preload Dashboard Data ---
  static Future<void> preloadDashboardData(double lat, double lon) async {
    await _ensureInitialized();
    if (currentUserId == null) return;

    updateUserLocation(lat, lon).then((success) async {
      if (success) {
        await Future.delayed(const Duration(seconds: 12));
        getWeatherForecast(forceRefresh: true);
        getMarketData(forceRefresh: true);
      }
    });
  }

  // --- 17. Sync Government Schemes ---
  static Future<void> syncGovSchemes() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check local storage
    String? storedSchemes = prefs.getString('saved_schemes');
    List<dynamic> tempSchemes = storedSchemes != null ? jsonDecode(storedSchemes) : [];

    // 🟢 FORCE LOAD FROM CSV if cache is empty OR null
    if (storedSchemes == null || tempSchemes.isEmpty) {
      if (kDebugMode) print("App cache is empty! Force-loading from offline CSV...");
      await _loadSchemesFromOfflineCSV(prefs);
    } else {
      // 🟡 Cache exists and has data
      localSchemes = tempSchemes;
      if (kDebugMode) print("Loaded ${localSchemes.length} schemes from local cache.");
    }

    // 2. Find the highest ID we currently have (to ask for Delta Sync)
    int lastId = 0;
    if (localSchemes.isNotEmpty) {
      lastId = localSchemes.map<int>((s) => s['id'] as int).reduce((a, b) => a > b ? a : b);
    }

    // 3. Ask backend for anything NEWER than lastId
    final url = Uri.parse('$baseUrl/api/schemes/sync?last_id=$lastId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> newSchemes = decoded['data'];

        if (newSchemes.isNotEmpty) {
          localSchemes.addAll(newSchemes);
          await prefs.setString('saved_schemes', jsonEncode(localSchemes));
          if (kDebugMode) print("✅ Synced ${newSchemes.length} new schemes from Server!");
        } else {
          if (kDebugMode) print("✅ Schemes are up to date.");
        }
      }
    } catch (e) {
      if (kDebugMode) print("❌ syncGovSchemes network error (Backend might be off): $e");
    }
  }

  // --- Helper Function: Parse Offline CSV ---
  static Future<void> _loadSchemesFromOfflineCSV(SharedPreferences prefs) async {
    try {
      final csvString = await rootBundle.loadString('assets/data/cleaned_schemes.csv');

      // 🔥 FIX: Removed eol: '\n' so it automatically handles Windows \r\n formats
      List<List<dynamic>> csvTable = const CsvToListConverter(
        shouldParseNumbers: true,
      ).convert(csvString);

      List<Map<String, dynamic>> parsedSchemes = [];

      for (int i = 1; i < csvTable.length; i++) {
        var row = csvTable[i];

        if (row.length >= 9) {
          parsedSchemes.add({
            'id': row[0] is int ? row[0] : int.tryParse(row[0].toString()) ?? 0,
            'slug': row[1].toString(),
            'scheme_name': row[2].toString(),
            'description': row[3].toString(),
            'states': row[4].toString(),
            'level': row[5].toString(),
            'scheme_for': row[6].toString(),
            'close_date': row[7] == null ? '' : row[7].toString(),
            'tags': row[8].toString(),
          });
        }
      }

      localSchemes = parsedSchemes;
      await prefs.setString('saved_schemes', jsonEncode(localSchemes));

      if (kDebugMode) print("✅ Successfully parsed & saved ${parsedSchemes.length} schemes from CSV!");

    } catch (e) {
      if (kDebugMode) print("❌ Failed to parse offline CSV: $e");
    }
  }

  // --- 18. Get Crop Advice ---
  static Future<Map<String, dynamic>?> getCropAdvice() async {
    await _ensureInitialized();
    if (currentUserId == null) return null;

    final url = Uri.parse('$baseUrl/users/$currentUserId/crop-advice');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (kDebugMode) print("❌ getCropAdvice failed: ${response.statusCode}");
      return null;
    } catch (e) {
      if (kDebugMode) print("❌ getCropAdvice error: $e");
      return null;
    }
  }
}