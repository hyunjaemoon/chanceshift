import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isMuted = true;

  bool get isMuted => _isMuted;

  Future<void> initialize() async {
    if (!_isInitialized && !kIsWeb) {
      await _audioPlayer.setSource(AssetSource('audio/chanceshift_theme.mp3'));
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.pause();
      _isInitialized = true;
    }
  }

  Future<void> toggleMute() async {
    if (!_isInitialized) return;

    _isMuted = !_isMuted;
    if (_isMuted) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
