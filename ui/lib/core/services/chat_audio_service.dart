import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:agriassist/services/api_service.dart';

class ChatAudioService {
  // Singleton instance
  static final ChatAudioService _instance = ChatAudioService._internal();
  factory ChatAudioService() => _instance;

  ChatAudioService._internal() {
    _player.onPlayerComplete.listen((event) {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  int? _playingMessageIndex;
  VoidCallback? _onPlayingIndexChanged;

  int? get playingMessageIndex => _playingMessageIndex;

  void addPlayingIndexListener(VoidCallback listener) => _onPlayingIndexChanged = listener;
  void removePlayingIndexListener() => _onPlayingIndexChanged = null;

  void dispose() {
    stop();
    removePlayingIndexListener();
  }

  Future<void> play(int messageId, int index) async {
    // If tapping the currently playing message, stop it
    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    await stop();

    _playingMessageIndex = index;
    _onPlayingIndexChanged?.call();

    try {
      // 1. Get the streaming URL (No more downloading bytes!)
      final String? streamUrl = await ApiService.getTtsAudioUrl(messageId);

      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception("Failed to get audio stream URL from server.");
      }

      // 2. Play directly from the live HTTP stream!
      // The native media player handles chunk-by-chunk playback automatically.
      await _player.play(UrlSource(streamUrl));

    } catch (e) {
      debugPrint("TTS Streaming Play Error: $e");
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint("Stop Error: $e");
    } finally {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    }
  }
}