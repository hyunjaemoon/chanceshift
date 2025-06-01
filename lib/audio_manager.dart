import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _hitPlayer = AudioPlayer();
  final AudioPlayer _whooshPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isMuted = true;

  bool get isMuted => _isMuted;

  Future<void> initialize() async {
    if (!_isInitialized && !kIsWeb) {
      await _audioPlayer.setSource(AssetSource('audio/chanceshift_theme.mp3'));
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.pause();

      await _hitPlayer.setSource(AssetSource('audio/hit.wav'));
      await _hitPlayer.setVolume(0.5);

      await _whooshPlayer.setSource(AssetSource('audio/whoosh.mp3'));
      await _whooshPlayer.setVolume(0.5);

      _isInitialized = true;
    }
  }

  Future<void> playHit() async {
    if (!_isInitialized || _isMuted) return;
    await _hitPlayer.seek(Duration.zero);
    await _hitPlayer.resume();
  }

  Future<void> playWhoosh() async {
    if (!_isInitialized || _isMuted) return;
    await _whooshPlayer.seek(Duration.zero);
    await _whooshPlayer.resume();
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
    await _hitPlayer.dispose();
    await _whooshPlayer.dispose();
  }
}
