import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agriassist/features/chat/voice_chat/bot_listening_screen.dart';
import 'package:agriassist/features/market/market_screen.dart';
import './text_chat/text_chat_screen.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/app_sidebar.dart';
import '../../core/services/location_service.dart';
import 'package:agriassist/services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../weather/weather_screen.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Fire the preload sequence as soon as the screen loads
    _silentlyPreloadData();
  }

  void _silentlyPreloadData() async {
    try {
      // 1. Get GPS coordinates
      Position position = await _locationService.getCurrentLocation();

      // 2. Trigger the sequence in ApiService
      ApiService.preloadDashboardData(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) print("Location access denied or failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF8F1),
        drawer: const AppSidebar(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF13383A), size: 30),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: const Text(
            'AgriAssist',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF13383A),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF13383A), size: 30),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔹 TOP OPTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _optionCard(
                          context,
                          '🌦️ Weather Report',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen()))
                      ),
                      const SizedBox(width: 12),
                      _optionCard(
                          context,
                          '💰 Bazaar Bhav',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketScreen()))
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _optionCard(
                          context,
                          '🌱 Crop Advice',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TextChatScreen(prefilledQuery: '🌱 Crop Advice')))
                      ),
                      const SizedBox(width: 12),
                      _optionCard(
                          context,
                          '🐄 Livestock Care',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TextChatScreen(prefilledQuery: '🐄 Livestock Care')))
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// 👨‍🌾 FARMER IMAGE
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFB5CAC1), width: 20),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/farmer_character.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              'Click on mic to start talking...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            /// 🎤 BOTTOM CONTROLS
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TextChatScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF5FBF9),
                            border: Border.all(color: const Color(0xFFB5CAC1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.message_outlined,
                            color: Color(0xFF13383A),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BotListeningScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF13383A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13383A).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(BuildContext context, String title, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF13383A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}