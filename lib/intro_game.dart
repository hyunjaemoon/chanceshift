import 'package:chanceshift/chanceshfit_logic.dart';
import 'package:chanceshift/audio_manager.dart';
import 'package:flame/game.dart' as flame;
import 'package:flame/components.dart' as flame;
import 'package:flame/events.dart' as flame;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'start_game.dart';

class FloatingTitle extends flame.SpriteComponent with flame.HasGameReference {
  double _time = 0;
  final double _amplitude = 10;
  final double _frequency = 2;
  final double _baseY;

  FloatingTitle({
    required flame.Sprite sprite,
    required flame.Vector2 size,
    required flame.Vector2 position,
  })  : _baseY = position.y,
        super(sprite: sprite, size: size, position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // Keep the floating animation within bounds
    position.y = _baseY + math.sin(_time * _frequency) * _amplitude;
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
  final double _baseY;

  ButtonComponent({
    required this.onTap,
    required this.imagePath,
    required flame.Vector2 position,
    required flame.Vector2 size,
  })  : _baseY = position.y,
        super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(imagePath);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Floating animation with bounds checking
    if (!_isPressed) {
      final floatOffset =
          math.sin(_time * _floatFrequency) * _floatAmplitude * dt;
      position.y = _baseY + floatOffset;
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

class FloatingDemoImage extends flame.SpriteComponent
    with flame.HasGameReference {
  double _time = 0;
  final double _amplitude = 10;
  final double _frequency = 2;

  FloatingDemoImage({
    required flame.Sprite sprite,
    required flame.Vector2 size,
    required flame.Vector2 position,
  }) : super(sprite: sprite, size: size, position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y = position.y + math.sin(_time * _frequency) * _amplitude * dt;
  }
}

class CreditsDisplay extends flame.TextComponent with flame.HasGameReference {
  CreditsDisplay()
      : super(
          text: '© ${DateTime.now().year} Hyun Jae Moon\nAll Rights Reserved',
          textRenderer: flame.TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = flame.Vector2(
      game.size.x / 2 - 150,
      game.size.y / 2 - 50,
    );
  }
}

class IntroGame extends flame.FlameGame {
  double _time = 0;
  final _random = math.Random();
  double _particleSpawnTimer = 0;
  static const double _particleSpawnInterval = 0.05;
  final _audioManager = AudioManager();
  BuildContext? _context;
  final ChanceShiftLogic chanceShiftLogic;

  IntroGame({required this.chanceShiftLogic});

  void setContext(BuildContext context) {
    _context = context;
  }

  void _showCreditsDialog() {
    if (_context != null) {
      showDialog(
        context: _context!,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black.withAlpha(230),
            title: const Text(
              'Credits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '© ${DateTime.now().year} Hyun Jae Moon\nAll Rights Reserved',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize audio
    await _audioManager.initialize();

    // Add the floating title sprite
    final titleSprite = FloatingTitle(
      sprite: await loadSprite('chanceshift_title.png'),
      size: flame.Vector2(300, 100),
      position: flame.Vector2(
          size.x / 2 - 150, size.y * 0.2), // Position at 20% from top
    );

    // Get the actual image dimensions
    final image = await images.load('chanceshift_title.png');
    final aspectRatio = image.width / image.height;

    // Adjust the size while maintaining aspect ratio
    final targetWidth =
        math.min(300.0, size.x * 0.8); // Limit width to 80% of screen
    final targetHeight = targetWidth / aspectRatio;
    titleSprite.size = flame.Vector2(targetWidth, targetHeight);

    // Recalculate position to keep it centered horizontally
    titleSprite.position = flame.Vector2(
      size.x / 2 - targetWidth / 2,
      size.y * 0.2, // Position at 20% from top
    );
    add(titleSprite);

    // Add demo image with adjusted positioning
    final demoImage = await loadSprite('demo.png');
    final demoImageComponent = flame.SpriteComponent(
      sprite: demoImage,
      size: flame.Vector2(50, 20),
      position: flame.Vector2(
        size.x / 2 - 25,
        titleSprite.position.y + titleSprite.size.y + 20, // Add some spacing
      ),
    );
    add(demoImageComponent);

    // Calculate button positions based on demo image position with proper spacing
    final buttonY = demoImageComponent.position.y +
        demoImageComponent.size.y +
        40; // Increased spacing
    final buttonSpacing = 80.0; // Increased spacing between buttons

    // Add start game button
    final startGameButton = ButtonComponent(
      imagePath: 'start_game.png',
      position: flame.Vector2(size.x / 2 - 100, buttonY),
      size: flame.Vector2(200, 60),
      onTap: () async {
        if (_context != null) {
          Navigator.of(_context!).push(
            MaterialPageRoute(
              builder: (context) => StartGamePage(
                chanceShiftLogic: this.chanceShiftLogic,
              ),
            ),
          );
        }
      },
    );
    add(startGameButton);

    // Add credits button with adjusted spacing
    final creditsButton = ButtonComponent(
      imagePath: 'credits.png',
      position: flame.Vector2(size.x / 2 - 100, buttonY + buttonSpacing),
      size: flame.Vector2(200, 60),
      onTap: () async {
        _showCreditsDialog();
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
        final particle = MovingParticle(
          position: flame.Vector2(
            _random.nextDouble() * size.x,
            size.y + 10,
          ),
          velocity: flame.Vector2(
            (_random.nextDouble() - 0.5) * 150,
            -_random.nextDouble() * 300 - 100,
          ),
          lifetime: _random.nextDouble() * 3 + 2,
          radius: _random.nextDouble() * 2 + 1,
          paint: Paint()..color = Colors.white.withOpacity(0.7),
        );

        add(particle);
      }
    }
  }

  @override
  void onRemove() {
    _audioManager.dispose();
    super.onRemove();
  }
}

class IntroPage extends StatefulWidget {
  final ChanceShiftLogic chanceShiftLogic;
  const IntroPage({super.key, required this.chanceShiftLogic});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late final IntroGame _game;

  @override
  void initState() {
    super.initState();
    _game = IntroGame(chanceShiftLogic: widget.chanceShiftLogic);
    _game.setContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWithInputBanner(game: _game),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: Icon(
                    _game._audioManager.isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _game._audioManager.toggleMute();
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameWithInputBanner extends StatelessWidget {
  final IntroGame game;

  const GameWithInputBanner({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: GameWidget(game: game),
    );
  }
}
