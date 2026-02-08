import 'package:flutter/material.dart';

// Onboarding Screen Imports
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/phone_screen.dart';
import '../features/onboarding/otp_screen.dart';
import '../features/onboarding/personalization_screen.dart';
import '../features/onboarding/name_screen.dart';

// Chat Feature Imports
import '../features/chat/voice_chat_screen.dart';
import '../features/chat/bot_listening_screen.dart';
import '../features/chat/text_chat/text_chat_screen.dart';
import '../features/chat/settings_screen.dart'; // 👈 ADD THIS

class AppRoutes {
  static const String splash = '/';
  static const String phone = '/phone';
  static const String otp = '/otp';
  static const String personalization = '/personalization';
  static const String name = '/name';
  static const String voiceChat = '/voice-chat';
  static const String botListening = '/bot-listening';
  static const String textChat = '/text-chat';
  static const String settings = '/settings'; // 👈 ADD THIS

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    phone: (context) => const PhoneScreen(),
    otp: (context) => const OtpScreen(),
    personalization: (context) => const PersonalizationScreen(),
    name: (context) => const NameScreen(),
    voiceChat: (context) => const VoiceChatScreen(),
    botListening: (context) => const BotListeningScreen(),
    textChat: (context) => const TextChatScreen(),
    settings: (context) => const SettingsScreen(), // 👈 ADD THIS
  };
}
