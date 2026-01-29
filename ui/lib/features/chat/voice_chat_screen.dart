import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class VoiceChatScreen extends StatelessWidget {
  const VoiceChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("AgriAssist", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Row(
                  children: [
                    const Icon(Icons.notifications_none, size: 30),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 30),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.textChat),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildInfoChip(Icons.trending_up, "Today's weather"),
            const SizedBox(height: 12),
            _buildInfoChip(Icons.trending_up, "Latest fertilizers"),
            const Spacer(),
            // Central Character Image
            const CircleAvatar(
              radius: 120,
              backgroundColor: Color(0xFFB2D8C3),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Icon(Icons.person, size: 100), // Replace with asset image from screenshot
              ),
            ),
            const Spacer(),
            const Text("Click on mic to start talking...", style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.botListening),
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.8),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 8),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}