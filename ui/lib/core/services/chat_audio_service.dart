import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
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
    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    await stop();

    _playingMessageIndex = index;
    _onPlayingIndexChanged?.call();

    try {
      // 1. Fetch MP3 bytes from backend
      final Uint8List? audioBytes = await ApiService.getTtsAudio(messageId);

      if (audioBytes == null || audioBytes.isEmpty) {
        throw Exception("Failed to load audio from server.");
      }

      // 2. Write bytes to a temporary physical file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tts_message_$messageId.mp3');
      await file.writeAsBytes(audioBytes, flush: true);

      // 3. Play from the physical file
      await _player.play(DeviceFileSource(file.path));

    } catch (e) {
      debugPrint("TTS Play Error: $e");
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