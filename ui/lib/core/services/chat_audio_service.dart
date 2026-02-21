import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

class ChatAudioService {
  ChatAudioService() {
    initBindings();
  }

  final AudioPlayer _player = AudioPlayer();

  OfflineTts? _ttsHi;
  OfflineTts? _ttsEn;

  int? _playingMessageIndex;
  VoidCallback? _onPlayingIndexChanged;

  int? get playingMessageIndex => _playingMessageIndex;

  void addPlayingIndexListener(VoidCallback listener) {
    _onPlayingIndexChanged = listener;
  }

  void removePlayingIndexListener() {
    _onPlayingIndexChanged = null;
  }

  Future<void> play(String rawText, int index,
      {String languageCode = "auto"}) async {
    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    await stop();

    _playingMessageIndex = index;
    _onPlayingIndexChanged?.call();

    try {
      String spokenText = _cleanMarkdown(rawText);
      if (spokenText.trim().isEmpty) {
        spokenText = "maiti uplabdh nahi";
      }

      // 🔥 AUTO LANGUAGE DETECTION
      final lang = languageCode == "auto"
          ? _detectLanguage(spokenText)
          : _mapLanguage(languageCode);

      await _ensureVoice(lang);

      final tts = lang == 'en' ? _ttsEn : _ttsHi;

      if (tts == null) {
        throw StateError('Voice not initialized for $lang');
      }

      final audio = tts.generate(text: spokenText, speed: 1.0);
      final wav = _writeWav(audio.samples, audio.sampleRate);

      await _player.play(BytesSource(wav));

      _player.onPlayerComplete.listen((event) {
        _playingMessageIndex = null;
        _onPlayingIndexChanged?.call();
      });
    } catch (e) {
      _playingMessageIndex = null;
      _onPlayingIndexChanged?.call();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playingMessageIndex = null;
    _onPlayingIndexChanged?.call();
  }

  void dispose() {
    _player.dispose();
    _onPlayingIndexChanged = null;
  }

  // ===========================
  // SHERPA VOICE LOADING
  // ===========================

  Future<void> _ensureVoice(String lang) async {
    switch (lang) {
      case 'en':
        if (_ttsEn != null) return;
        final dir = await _ensureDir('vits-en-US');
        final modelInfo = _ModelInfo.enUSLibriRMedium();
        await _downloadAndExtractIfNeeded(
            dir, modelInfo.archiveUrl, modelInfo.rootDir);
        _ttsEn = _createVits(
          modelDir: '${dir.path}/${modelInfo.rootDir}',
          modelName: modelInfo.modelName,
          dataDir: 'espeak-ng-data',
        );
        return;

      case 'hi':
      case 'mr':
        if (_ttsHi != null) return;
        final dir = await _ensureDir('vits-hi-IN');
        final modelInfo = _ModelInfo.hiINRohanMedium();
        await _downloadAndExtractIfNeeded(
            dir, modelInfo.archiveUrl, modelInfo.rootDir);
        _ttsHi = _createVits(
          modelDir: '${dir.path}/${modelInfo.rootDir}',
          modelName: modelInfo.modelName,
          dataDir: 'espeak-ng-data',
        );
        return;
    }
  }

  Future<Directory> _ensureDir(String name) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$name');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  OfflineTts _createVits({
    required String modelDir,
    required String modelName,
    required String dataDir,
  }) {
    final config = OfflineTtsConfig(
      model: OfflineTtsModelConfig(
        vits: OfflineTtsVitsModelConfig(
          model: '$modelDir/$modelName',
          tokens: '$modelDir/tokens.txt',
          dataDir: '$modelDir/$dataDir',
        ),
      ),
    );
    return OfflineTts(config);
  }

  Future<void> _downloadAndExtractIfNeeded(
      Directory dir, String url, String rootDir) async {
    final root = Directory('${dir.path}/$rootDir');
    if (root.existsSync()) return;

    final archivePath = '${dir.path}/model.tar.bz2';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Failed to download model (${resp.statusCode})');
    }

    await File(archivePath).writeAsBytes(resp.bodyBytes);

    final inputStream = InputFileStream(archivePath);
    final bz = BZip2Decoder().decodeBuffer(inputStream);
    final tarStream = InputStream(bz);
    final tar = TarDecoder();
    tar.decodeBuffer(tarStream);

    for (final f in tar.files) {
      final outPath = '${dir.path}/${f.filename}';
      if (f.isFile) {
        final outFile = File(outPath);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(f.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }

    File(archivePath).deleteSync();
  }

  // ===========================
  // WAV CONVERSION
  // ===========================

  Uint8List _writeWav(Float32List samples, int sampleRate) {
    final bytes = _float32ToInt16(samples);
    final totalDataLen = 44 + bytes.length;
    final byteData = BytesBuilder();

    byteData.add(_ascii('RIFF'));
    byteData.add(_u32(totalDataLen - 8));
    byteData.add(_ascii('WAVE'));
    byteData.add(_ascii('fmt '));
    byteData.add(_u32(16));
    byteData.add(_u16(1));
    byteData.add(_u16(1));
    byteData.add(_u32(sampleRate));
    byteData.add(_u32(sampleRate * 2));
    byteData.add(_u16(2));
    byteData.add(_u16(16));
    byteData.add(_ascii('data'));
    byteData.add(_u32(bytes.length));
    byteData.add(bytes);

    return byteData.toBytes();
  }

  Uint8List _float32ToInt16(Float32List samples) {
    final out = BytesBuilder();
    for (var i = 0; i < samples.length; i++) {
      var v =
      (samples[i] * 32767.0).clamp(-32768.0, 32767.0).toInt();
      out.addByte(v & 0xff);
      out.addByte((v >> 8) & 0xff);
    }
    return out.toBytes();
  }

  Uint8List _ascii(String s) =>
      Uint8List.fromList(s.codeUnits);

  Uint8List _u16(int v) =>
      Uint8List.fromList([v & 0xff, (v >> 8) & 0xff]);

  Uint8List _u32(int v) => Uint8List.fromList([
    v & 0xff,
    (v >> 8) & 0xff,
    (v >> 16) & 0xff,
    (v >> 24) & 0xff,
  ]);

  String _mapLanguage(String languageCode) {
    if (languageCode.startsWith("en")) return "en";
    if (languageCode.startsWith("hi")) return "hi";
    if (languageCode.startsWith("mr")) return "mr";
    return "en";
  }

  String _detectLanguage(String text) {
    // Check if text contains Devanagari
    final hasDevanagari = text.runes.any(
            (c) => (c >= 0x0900 && c <= 0x097F) || c == 0x200D);

    if (!hasDevanagari) {
      return 'en';
    }

    final marathiWords = [
      'आहे','आणि','काय','नाही','मला','तुम्ही','आपण','होय','नमस्कार'
    ];

    final hindiWords = [
      'है','और','क्या','नहीं','मुझे','आप','नमस्ते'
    ];

    int mrScore = 0;
    int hiScore = 0;

    for (var w in marathiWords) {
      if (text.contains(w)) mrScore++;
    }

    for (var w in hindiWords) {
      if (text.contains(w)) hiScore++;
    }

    if (mrScore > hiScore) return 'mr';
    return 'hi';
  }

  String _cleanMarkdown(String text) {
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAllMapped(
        RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(
        RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(
        RegExp(r'(\*\*|__)(.*?)\1'), (m) => m.group(2) ?? "");
    text = text.replaceAllMapped(
        RegExp(r'(\*|_)(.*?)\1'), (m) => m.group(2) ?? "");
    text =
        text.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    text =
        text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    text = text.replaceAll(
        RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(
        RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    text =
        text.replaceAll(RegExp(r'!\[(.*?)\]\(.*?\)'), '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _ModelInfo {
  final String archiveUrl;
  final String rootDir;
  final String modelName;

  _ModelInfo(this.archiveUrl, this.rootDir, this.modelName);

  static _ModelInfo enUSLibriRMedium() => _ModelInfo(
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-libritts_r-medium.tar.bz2',
    'vits-piper-en_US-libritts_r-medium',
    'en_US-libritts_r-medium.onnx',
  );

  static _ModelInfo hiINRohanMedium() => _ModelInfo(
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-hi_IN-rohan-medium.tar.bz2',
    'vits-piper-hi_IN-rohan-medium',
    'hi_IN-rohan-medium.onnx',
  );
}