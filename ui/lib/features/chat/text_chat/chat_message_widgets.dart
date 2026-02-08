import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'chat_audio_service.dart';

class ChatMessageWidgets {
  static Widget botBubble({
    required BuildContext context,
    required String text,
    required int index,
    required int? messageId,
    required ChatAudioService audioService,
    required Function(String) onCopyPressed,
  }) {
    final isPlaying = audioService.playingMessageIndex == index;
    final isLoadingAudio = isPlaying && audioService.isFetchingAudio;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isPlaying ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: isPlaying
                    ? Border.all(color: Colors.green.withOpacity(0.5))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: MarkdownBody(data: text),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  _actionButton(
                    child: isLoadingAudio
                        ? const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0E3D3D))
                    )
                        : Icon(
                      isPlaying ? Icons.stop : Icons.volume_up,
                      size: 18,
                      color: isPlaying ? Colors.red : const Color(0xFF0E3D3D),
                    ),
                    color: isPlaying ? Colors.red : const Color(0xFF0E3D3D),
                    tooltip: isPlaying ? 'Stop' : 'Listen',
                    onPressed: () => audioService.handleAudioPlay(index, messageId),
                  ),
                  const SizedBox(width: 10),
                  _actionButton(
                    child: const Icon(Icons.content_copy, size: 18, color: Color(0xFF0E3D3D)),
                    color: const Color(0xFF0E3D3D),
                    tooltip: 'Copy',
                    onPressed: () => onCopyPressed(text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFF4C8BF5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  static Widget typingBubble(String text, int index) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(text, style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _actionButton({
    required Widget child,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}