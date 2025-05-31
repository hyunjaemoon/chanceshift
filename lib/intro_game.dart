import 'package:flame/game.dart' as flame;
import 'package:flame/components.dart' as flame;
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingTitle extends flame.SpriteComponent with flame.HasGameRef {
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
    position.y = gameRef.size.y / 3 + math.sin(_time * _frequency) * _amplitude;
  }
}

class MovingParticle extends flame.CircleComponent with flame.HasGameRef {
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
    paint.color = Colors.white.withOpacity(opacity);

    if (_time >= lifetime) {
      removeFromParent();
    }
  }
}

class IntroGame extends flame.FlameGame {
  double _time = 0;
  final _random = math.Random();
  double _particleSpawnTimer = 0;
  static const double _particleSpawnInterval = 0.05; // Increased spawn rate

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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
