import 'package:flutter/material.dart';
import './text_chat/text_chat_screen.dart';

class BotListeningScreen extends StatefulWidget {
  const BotListeningScreen({super.key});

  @override
  State<BotListeningScreen> createState() => _BotListeningScreenState();
}

class _BotListeningScreenState extends State<BotListeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _rippleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1),
      appBar: AppBar(
        title: const Text('AgriAssist', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFEAF8F1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          /// 🔊 PROFILE PHOTO — SMOOTH RIPPLE
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// 🌊 SMOOTH BREATHING RIPPLE
                AnimatedBuilder(
                  animation: _rippleAnim,
                  builder: (_, __) {
                    final scale = 1 + (_rippleAnim.value * 0.30);
                    final opacity = (1 - _rippleAnim.value) * 0.6;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withOpacity(opacity),
                            width: 10,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                /// 🧑‍🌾 PROFILE IMAGE
                CircleAvatar(
                  radius: 85,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/farmer_listening.png',
                      height: 170,
                      width: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Listening...',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),

          const Spacer(),

          /// 🔽 BOTTOM CONTROLS
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// 🎤 MIC BUTTON (REFERENCE RIPPLE)
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _rippleAnim,
                          builder: (_, __) {
                            final scale = 1 + (_rippleAnim.value * 0.6);
                            final opacity =
                                (1 - _rippleAnim.value) * 0.5;

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                  Colors.green.withOpacity(opacity),
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E3D3D),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ❌ CLOSE BUTTON
                  Positioned(
                    left: screenWidth / 2 + 80,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TextChatScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
