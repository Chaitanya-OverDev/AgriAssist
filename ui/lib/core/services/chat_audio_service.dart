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
  // ===========================
  // SINGLETON SETUP
  // ===========================
  static final ChatAudioService _instance = ChatAudioService._internal();
  factory ChatAudioService() => _instance;
  ChatAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  OfflineTts? _ttsHi;
  OfflineTts? _ttsEn;

  int? _playingMessageIndex;
  VoidCallback? _onPlayingIndexChanged;

  int? get playingMessageIndex => _playingMessageIndex;

  void addPlayingIndexListener(VoidCallback listener) => _onPlayingIndexChanged = listener;
  void removePlayingIndexListener() => _onPlayingIndexChanged = null;

  /// REQUIRED FIX: Added dispose method to resolve compilation errors
  void dispose() {
    stop();
    // In a singleton, we don't usually dispose the _player entirely 
    // unless the app is closing, but we provide this to satisfy the UI.
  }

  // ===========================
  // MAIN PLAY LOGIC
  // ===========================
  Future<void> play(String rawText, int index, {String languageCode = "auto"}) async {
    if (rawText.trim().isEmpty) return;

    if (_playingMessageIndex == index) {
      await stop();
      return;
    }

    await stop();
    _playingMessageIndex = index;
    _onPlayingIndexChanged?.call();

    try {
      String spokenText = _cleanMarkdown(rawText);
      if (spokenText.isEmpty) return;

      final lang = languageCode == "auto" 
          ? _detectLanguage(spokenText) 
          : _mapLanguage(languageCode);
      
      await _ensureVoice(lang);

      final tts = lang == 'en' ? _ttsEn : _ttsHi;
      if (tts == null) throw StateError('Voice not initialized');

      final List<String> fragments = _splitIntoSentences(spokenText);
      final List<Float32List> allSamples = [];
      int sampleRate = 22050;

      for (String fragment in fragments) {
        final textToGenerate = fragment.trim();
        if (textToGenerate.isEmpty) continue;
        try {
          final audio = tts.generate(text: textToGenerate, speed: 1.0);
          if (audio.samples.isNotEmpty) {
            allSamples.add(audio.samples);
            sampleRate = audio.sampleRate;
          }
        } catch (e) {
          debugPrint("Sherpa skipped bad fragment: $textToGenerate");
          continue; 
        }
      }

      if (allSamples.isEmpty) return;

      final totalLength = allSamples.fold(0, (sum, list) => sum + list.length);
      final combinedSamples = Float32List(totalLength);
      int offset = 0;
      for (var list in allSamples) {
        combinedSamples.setAll(offset, list);
        offset += list.length;
      }

      final wav = _writeWav(combinedSamples, sampleRate);
      await _player.play(BytesSource(wav));

      _player.onPlayerComplete.listen((event) {
        _playingMessageIndex = null;
        _onPlayingIndexChanged?.call();
      });
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

  // ===========================
  // HELPERS: CLEANING & SPLITTING
  // ===========================

  List<String> _splitIntoSentences(String text) {
    final RegExp sentenceSplitter = RegExp(r'([^.!?।\n,]+[.!?।\n,]*)');
    final Iterable<Match> matches = sentenceSplitter.allMatches(text);
    List<String> result = matches.map((m) => m.group(0)!.trim()).toList();
    return result.isEmpty ? [text] : result;
  }

  String _cleanMarkdown(String text) {
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAllMapped(RegExp(r'(\*\*|__|`|\*|_)(.*?)\1'), (m) => m.group(2) ?? "");
    text = text.replaceAll(RegExp(r'[.*:#_~]'), ' '); 
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ===========================
  // MODEL MANAGEMENT
  // ===========================

  Future<void> _ensureVoice(String lang) async {
    if (lang == 'en' && _ttsEn != null) return;
    if ((lang == 'hi' || lang == 'mr') && _ttsHi != null) return;

    final name = lang == 'en' ? 'vits-en-US' : 'vits-hi-IN';
    final dir = await _ensureDir(name);
    final modelInfo = lang == 'en' ? _ModelInfo.enUSLibriRMedium() : _ModelInfo.hiINRohanMedium();

    await _downloadAndExtractIfNeeded(dir, modelInfo.archiveUrl, modelInfo.rootDir);

    final tts = _createVits(
      modelDir: '${dir.path}/${modelInfo.rootDir}',
      modelName: modelInfo.modelName,
      dataDir: 'espeak-ng-data',
    );

    if (lang == 'en') _ttsEn = tts; else _ttsHi = tts;
  }

  Future<Directory> _ensureDir(String name) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$name');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  OfflineTts _createVits({required String modelDir, required String modelName, required String dataDir}) {
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

  Future<void> _downloadAndExtractIfNeeded(Directory dir, String url, String rootDir) async {
    if (Directory('${dir.path}/$rootDir').existsSync()) return;
    final archivePath = '${dir.path}/model.tar.bz2';
    final resp = await http.get(Uri.parse(url));
    await File(archivePath).writeAsBytes(resp.bodyBytes);
    await compute(_extractArchiveTask, {'archivePath': archivePath, 'destinationDir': dir.path});
    File(archivePath).deleteSync();
  }

  static void _extractArchiveTask(Map<String, String> params) {
    final inputStream = InputFileStream(params['archivePath']!);
    
    // API Fix: Wrapping decompressed data for TarDecoder
    final bz2Data = BZip2Decoder().decodeBuffer(inputStream);
    final tarInputStream = InputStream(bz2Data);
    final Archive archive = TarDecoder().decodeBuffer(tarInputStream);

    for (final f in archive.files) {
      final outPath = '${params['destinationDir']}/${f.name}';
      if (f.isFile) {
        File(outPath)..createSync(recursive: true)..writeAsBytesSync(f.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }
  }

  // ===========================
  // WAV & LANGUAGE UTILS
  // ===========================

  Uint8List _writeWav(Float32List samples, int sampleRate) {
    final bytes = _float32ToInt16(samples);
    final byteData = BytesBuilder();
    byteData.add(_ascii('RIFF'));
    byteData.add(_u32(36 + bytes.length));
    byteData.add(_ascii('WAVEfmt '));
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
    for (var s in samples) {
      int v = (s * 32767).clamp(-32768, 32767).toInt();
      out.addByte(v & 0xFF); out.addByte((v >> 8) & 0xFF);
    }
    return out.toBytes();
  }

  Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
  Uint8List _u16(int v) => Uint8List.fromList([v & 0xff, (v >> 8) & 0xff]);
  Uint8List _u32(int v) => Uint8List.fromList([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);

  String _detectLanguage(String text) {
    if (!text.runes.any((c) => c >= 0x0900 && c <= 0x097F)) return 'en';
    return text.contains('आहे') || text.contains('आणि') ? 'mr' : 'hi';
  }

  String _mapLanguage(String code) => code.startsWith("en") ? "en" : (code.startsWith("mr") ? "mr" : "hi");
}

class _ModelInfo {
  final String archiveUrl, rootDir, modelName;
  _ModelInfo(this.archiveUrl, this.rootDir, this.modelName);
  static _ModelInfo enUSLibriRMedium() => _ModelInfo('https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-libritts_r-medium.tar.bz2', 'vits-piper-en_US-libritts_r-medium', 'en_US-libritts_r-medium.onnx');
  static _ModelInfo hiINRohanMedium() => _ModelInfo('https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-hi_IN-rohan-medium.tar.bz2', 'vits-piper-hi_IN-rohan-medium', 'hi_IN-rohan-medium.onnx');
}