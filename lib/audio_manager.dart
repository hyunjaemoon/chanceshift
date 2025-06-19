import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Manages all audio playback for the ChanceShift game.
///
/// This class handles background music, sound effects, and audio state management.
/// It uses a singleton pattern to ensure consistent audio state across the app.
class AudioManager {
  // Singleton pattern
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio file paths
  static const String _backgroundMusicPath = 'audio/chanceshift_theme.mp3';
  static const String _hitSoundPath = 'audio/hit.wav';
  static const String _whooshSoundPath = 'audio/whoosh.mp3';

  // Audio configuration
  static const double _defaultVolume = 0.5;

  // Audio players for different sound types
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _hitSoundPlayer = AudioPlayer();
  final AudioPlayer _whooshSoundPlayer = AudioPlayer();

  // State management
  bool _isInitialized = false;
  bool _isMuted = true;
  bool _hasStartedMusic = false;

  /// Returns whether audio is currently muted
  bool get isMuted => _isMuted;

  /// Returns whether the audio system has been initialized
  bool get isInitialized => _isInitialized;

  /// Initializes the audio system and loads all sound files
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeBackgroundMusic();
      await _initializeSoundEffects();

      _isInitialized = true;
      print('AudioManager initialized successfully');

      // Start background music if not muted
      if (!_isMuted) {
        await startBackgroundMusic();
      }
    } catch (e) {
      print('Error initializing AudioManager: $e');
      // Even if initialization fails, we can still handle mute state
      _isInitialized = true;
    }
  }

  /// Initializes the background music player
  Future<void> _initializeBackgroundMusic() async {
    await _backgroundMusicPlayer.setSource(AssetSource(_backgroundMusicPath));
    await _backgroundMusicPlayer.setVolume(_defaultVolume);
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer.pause();
  }

  /// Initializes sound effect players
  Future<void> _initializeSoundEffects() async {
    // Initialize hit sound
    await _hitSoundPlayer.setSource(AssetSource(_hitSoundPath));
    await _hitSoundPlayer.setVolume(_defaultVolume);

    // Initialize whoosh sound
    await _whooshSoundPlayer.setSource(AssetSource(_whooshSoundPath));
    await _whooshSoundPlayer.setVolume(_defaultVolume);
  }

  /// Plays the hit sound effect
  Future<void> playHit() async {
    if (!_canPlayAudio()) return;

    try {
      await _hitSoundPlayer.seek(Duration.zero);
      await _hitSoundPlayer.resume();
    } catch (e) {
      print('Error playing hit sound: $e');
    }
  }

  /// Plays the whoosh sound effect
  Future<void> playWhoosh() async {
    if (!_canPlayAudio()) return;

    try {
      await _whooshSoundPlayer.seek(Duration.zero);
      await _whooshSoundPlayer.resume();
    } catch (e) {
      print('Error playing whoosh sound: $e');
    }
  }

  /// Toggles the mute state and handles audio accordingly
  Future<void> toggleMute() async {
    if (!_isInitialized) return;

    _isMuted = !_isMuted;

    try {
      if (_isMuted) {
        await _pauseAllAudio();
      } else {
        // When audio is first turned on, start the game music
        await startGameMusic();
      }
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  /// Pauses all audio players
  Future<void> _pauseAllAudio() async {
    await _backgroundMusicPlayer.pause();
    await _hitSoundPlayer.pause();
    await _whooshSoundPlayer.pause();
  }

  /// Starts the background music (respects mute state)
  Future<void> startBackgroundMusic() async {
    if (!_canPlayAudio()) return;

    try {
      await _backgroundMusicPlayer.resume();
      _hasStartedMusic = true;
    } catch (e) {
      print('Error starting background music: $e');
    }
  }

  /// Starts the game music (ignores mute state - volume handles it)
  Future<void> startGameMusic() async {
    if (!_isInitialized) return;

    try {
      // Always start the music when game begins, mute state will be handled by volume
      await _backgroundMusicPlayer.resume();
      _hasStartedMusic = true;
    } catch (e) {
      print('Error starting game music: $e');
    }
  }

  /// Checks if audio can be played (initialized and not muted)
  bool _canPlayAudio() {
    return _isInitialized && !_isMuted;
  }

  /// Disposes of all audio players and cleans up resources
  Future<void> dispose() async {
    try {
      await _backgroundMusicPlayer.dispose();
      await _hitSoundPlayer.dispose();
      await _whooshSoundPlayer.dispose();
    } catch (e) {
      print('Error disposing AudioManager: $e');
    }
  }
}
