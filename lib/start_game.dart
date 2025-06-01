import 'package:flame/game.dart' as flame;
import 'package:flame/components.dart' as flame;
import 'package:flame/events.dart' as flame;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'chanceshfit_logic.dart';
import 'audio_manager.dart';

class BinaryBox extends flame.PositionComponent {
  final bool isOne;
  final Paint _paint;

  BinaryBox({
    required super.position,
    required super.size,
    required this.isOne,
  }) : _paint = Paint()
          ..color = isOne ? Colors.green : Colors.grey
          ..style = PaintingStyle.fill;

  @override
  void render(ui.Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
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

class StartGame extends flame.FlameGame with flame.TapCallbacks {
  final List<bool> binarySequence = List.generate(10, (_) => false);
  final TextEditingController _textController = TextEditingController();
  double _time = 0;
  final _random = math.Random();
  double _particleSpawnTimer = 0;
  static const double _particleSpawnInterval = 0.05;
  BuildContext? _context;
  Function(String)? onAnswerSubmitted;
  ChanceShiftLogic? _chanceShiftLogic;

  void setContext(BuildContext context) {
    _context = context;
  }

  void setChanceShiftLogic(ChanceShiftLogic logic) {
    _chanceShiftLogic = logic;
  }

  void setOnAnswerSubmitted(Function(String) callback) {
    onAnswerSubmitted = callback;
  }

  Future<void> handleUserInput(String input) async {
    if (_chanceShiftLogic != null) {
      final result = await _chanceShiftLogic!.query(input);
      // Update the binary sequence with the output
      for (int i = 0; i < binarySequence.length; i++) {
        binarySequence[i] = result["output"]![i] == 1;
      }
      // Trigger a rebuild of the boxes
      onLoad();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add binary boxes
    final boxSize = flame.Vector2(40, 40);
    final spacing = 10.0;
    final startX = (size.x - (boxSize.x * 5 + spacing * 4)) / 2;
    final startY = size.y / 3;

    for (int i = 0; i < binarySequence.length; i++) {
      final row = i ~/ 5;
      final col = i % 5;
      final position = flame.Vector2(
        startX + (boxSize.x + spacing) * col,
        startY + (boxSize.y + spacing) * row,
      );

      add(BinaryBox(
        position: position,
        size: boxSize,
        isOne: binarySequence[i],
      ));
    }
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
            size.y + 10, // Start slightly below the screen
          ),
          velocity: flame.Vector2(
            (_random.nextDouble() - 0.5) * 150, // Horizontal spread
            -_random.nextDouble() * 300 - 100, // Upward velocity
          ),
          lifetime: _random.nextDouble() * 3 + 2, // Lifetime
          radius: _random.nextDouble() * 2 + 1, // Varied particle sizes
          paint: Paint()
            ..color = Colors.white.withOpacity(0.7), // Initial opacity
        );

        add(particle);
      }
    }
  }

  @override
  void onRemove() {
    _textController.dispose();
    super.onRemove();
  }
}

class StartGamePage extends StatefulWidget {
  final ChanceShiftLogic chanceShiftLogic;

  const StartGamePage({super.key, required this.chanceShiftLogic});

  @override
  State<StartGamePage> createState() => _StartGamePageState();
}

class _StartGamePageState extends State<StartGamePage> {
  final TextEditingController _textController = TextEditingController();
  late StartGame _game;
  final FocusNode _focusNode = FocusNode();
  final _audioManager = AudioManager();

  @override
  void initState() {
    super.initState();
    _game = StartGame()
      ..setContext(context)
      ..setChanceShiftLogic(widget.chanceShiftLogic)
      ..setOnAnswerSubmitted(_handleAnswerSubmitted);
  }

  void _handleAnswerSubmitted(String answer) {
    _game.handleUserInput(answer);
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    child: flame.GameWidget(
                      game: _game,
                    ),
                  ),
                ),
                Container(
                  color: Colors.black.withOpacity(0.8),
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter your answer...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: _handleAnswerSubmitted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () =>
                            _handleAnswerSubmitted(_textController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  _audioManager.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _audioManager.toggleMute();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
