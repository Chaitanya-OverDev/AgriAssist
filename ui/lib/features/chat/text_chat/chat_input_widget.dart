import 'package:flutter/material.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final bool isLoggedIn;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isLoggedIn,
              decoration: InputDecoration(
                hintText: isLoggedIn ? "Type message..." : "Please login to chat",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: isLoggedIn ? (_) => onSendPressed : null,
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