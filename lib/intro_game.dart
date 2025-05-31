import 'package:flame/game.dart' as flame;
import 'package:flame/components.dart' as flame;
import 'package:flame/events.dart' as flame;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'dart:ui' as ui;

class FloatingTitle extends flame.SpriteComponent with flame.HasGameReference {
  double _time = 0;
  final double _amplitude = 10;
  final double _frequency = 2;

  FloatingTitle({
    required flame.Sprite sprite,
    required flame.Vector2 size,
    required flame.Vector2 position,
  }) : super(sprite: sprite, size: size, position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y = game.size.y / 3 + math.sin(_time * _frequency) * _amplitude;
  }
}

class MovingParticle extends flame.CircleComponent with flame.HasGameReference {
  final flame.Vector2 velocity;
  double _time = 0;
  final double lifetime;

  MovingParticle({
    required super.position,
    required this.velocity,
    required this.lifetime,
    required super.radius,
    required super.paint,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position += velocity * dt;

    // Ensure opacity stays within valid bounds (0.0 to 1.0)
    final progress = (_time / lifetime).clamp(0.0, 1.0);
    final opacity = (1 - progress) * 0.7;
    paint.color = Colors.white.withAlpha((opacity * 255).round());

    if (_time >= lifetime) {
      removeFromParent();
    }
  }
}

class ButtonComponent extends flame.SpriteComponent
    with flame.HasGameReference, flame.TapCallbacks {
  final VoidCallback onTap;
  final String imagePath;
  double _time = 0;
  double _scale = 1.0;
  bool _isPressed = false;
  final double _floatAmplitude = 2.0;
  final double _floatFrequency = 1.5;
  final double _pressScale = 0.95;

  ButtonComponent({
    required this.onTap,
    required this.imagePath,
    required flame.Vector2 position,
    required flame.Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(imagePath);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Floating animation
    if (!_isPressed) {
      position.y =
          position.y + math.sin(_time * _floatFrequency) * _floatAmplitude * dt;
    }

    // Scale animation
    if (_isPressed) {
      _scale = _pressScale;
    } else {
      _scale = 1.0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(_scale);
    canvas.translate(-size.x / 2, -size.y / 2);
    super.render(canvas);
    canvas.restore();
  }

  @override
  void onTapDown(flame.TapDownEvent event) {
    _isPressed = true;
  }

  @override
  void onTapUp(flame.TapUpEvent event) {
    _isPressed = false;
    onTap();
  }

  @override
  void onTapCancel(flame.TapCancelEvent event) {
    _isPressed = false;
  }
}

class IntroGame extends flame.FlameGame {
  double _time = 0;
  final _random = math.Random();
  double _particleSpawnTimer = 0;
  static const double _particleSpawnInterval = 0.05;
  final _audioPlayer = AudioPlayer();
  bool _isAudioInitialized = false;

  @override
  Color backgroundColor() => Colors.black;

  Future<void> _initializeAudio() async {
    if (!_isAudioInitialized) {
      await _audioPlayer.setSource(AssetSource('audio/chanceshift_theme.mp3'));
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isAudioInitialized = true;
    }
  }

  Future<void> _startAudio() async {
    await _initializeAudio();
    await _audioPlayer.resume();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize audio for mobile platforms
    if (!kIsWeb) {
      await _initializeAudio();
      await _startAudio();
    }

    // Add the floating title sprite
    final titleSprite = FloatingTitle(
      sprite: await loadSprite('chanceshift_title.png'),
      size: flame.Vector2(300, 100),
      position: flame.Vector2(size.x / 2 - 150, size.y / 3),
    );

    // Get the actual image dimensions
    final image = await images.load('chanceshift_title.png');
    final aspectRatio = image.width / image.height;

    // Adjust the size while maintaining aspect ratio
    final targetWidth = 300.0;
    final targetHeight = targetWidth / aspectRatio;
    titleSprite.size = flame.Vector2(targetWidth, targetHeight);

    // Recalculate position to keep it centered horizontally
    titleSprite.position = flame.Vector2(
      size.x / 2 - targetWidth / 2,
      size.y / 3,
    );

    add(titleSprite);

    // Calculate button positions based on title position
    final buttonY = titleSprite.position.y +
        titleSprite.size.y +
        20; // Keep 20 pixels gap from logo

    // Add start game button
    final startGameButton = ButtonComponent(
      imagePath: 'start_game.png',
      position: flame.Vector2(size.x / 2 - 100, buttonY),
      size: flame.Vector2(200, 60),
      onTap: () async {
        await _startAudio();
        // TODO: Implement start game navigation
        print('Start game tapped');
      },
    );
    add(startGameButton);

    // Add credits button
    final creditsButton = ButtonComponent(
      imagePath: 'credits.png',
      position: flame.Vector2(size.x / 2 - 100, buttonY + 70),
      size: flame.Vector2(200, 60),
      onTap: () async {
        await _startAudio();
        // TODO: Implement credits navigation
        print('Credits tapped');
      },
    );
    add(creditsButton);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _particleSpawnTimer += dt;

    // Spawn particles at regular intervals
    while (_particleSpawnTimer >= _particleSpawnInterval) {
      _particleSpawnTimer -= _particleSpawnInterval;

      // Spawn multiple particles at once for a more continuous effect
      for (int i = 0; i < 5; i++) {
        // Increased number of particles
        final particle = MovingParticle(
          position: flame.Vector2(
            _random.nextDouble() * size.x,
            size.y + 10, // Start slightly below the screen
          ),
          velocity: flame.Vector2(
            (_random.nextDouble() - 0.5) * 150, // Increased horizontal spread
            -_random.nextDouble() * 300 - 100, // Increased upward velocity
          ),
          lifetime: _random.nextDouble() * 3 + 2, // Increased lifetime
          radius: _random.nextDouble() * 2 + 1, // Varied particle sizes
          paint: Paint()
            ..color = Colors.white.withOpacity(0.7), // Increased opacity
        );

        add(particle);
      }
    }
  }

  @override
  void onRemove() {
    _audioPlayer.dispose();
    super.onRemove();
  }
}

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: flame.GameWidget(
        game: IntroGame(),
      ),
    );
  }
}
