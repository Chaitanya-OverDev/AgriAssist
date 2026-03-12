import 'package:flutter/material.dart';
import 'package:agriassist/l10n/app_localizations.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onMicPressed;
  final bool isListening;
  final bool isLoggedIn;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.onMicPressed,
    required this.isListening,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isListening ? Icons.stop_circle : Icons.mic,
              color: isListening ? Colors.red : const Color(0xFF0E3D3D),
            ),
            onPressed: isLoggedIn ? onMicPressed : null,
          ),

          Expanded(
            child: TextField(
              controller: controller,
              enabled: isLoggedIn,
              decoration: InputDecoration(
                hintText: isListening
                    ? t.listening
                    : (isLoggedIn ? t.typeMessage : t.loginToChat),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: isLoggedIn ? (_) => onSendPressed() : null,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF0E3D3D)),
            onPressed: isLoggedIn ? onSendPressed : null,
          ),
        ],
      ),
    );
  }
}