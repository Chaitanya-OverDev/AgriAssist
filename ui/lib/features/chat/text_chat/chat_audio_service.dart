import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Add this import
import 'package:audioplayers/audioplayers.dart';
import '../../../services/api_service.dart';

class ChatAudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingMessageIndex;
  bool _isFetchingAudio = false;
  VoidCallback? _onPlayingIndexChanged;

  ChatAudioService() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_playingMessageIndex != null) {
        _playingMessageIndex = null;
        _onPlayingIndexChanged?.call();
      }
    });
  }

  void addPlayingIndexListener(VoidCallback listener) {
    _onPlayingIndexChanged = listener;
  }

  void removePlayingIndexListener() {
    _onPlayingIndexChanged = null;
  }

  int? get playingMessageIndex => _playingMessageIndex;
  bool get isFetchingAudio => _isFetchingAudio;

  Future<void> handleAudioPlay(int index, int? messageId) async {
    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    await stop();

    if (messageId == null) {
      return;
    }

    _playingMessageIndex = index;
    _isFetchingAudio = true;
    _onPlayingIndexChanged?.call();

    try {
      Uint8List? audioBytes = await ApiService.getTtsAudio(messageId);

      if (audioBytes != null) {
        await _audioPlayer.play(BytesSource(audioBytes));
      } else {
        _playingMessageIndex = null;
        _onPlayingIndexChanged?.call();
      }
    } catch (e) {
      print("Audio Play Error: $e");
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    } finally {
      _isFetchingAudio = false;
      _onPlayingIndexChanged?.call();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _playingMessageIndex = null;
    _onPlayingIndexChanged?.call();
  }

  void dispose() {
    _audioPlayer.dispose();
    _onPlayingIndexChanged = null;
  }
}