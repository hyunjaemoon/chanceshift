import 'package:flame/game.dart' as flame;
import 'package:flame/components.dart' as flame;
import 'package:flame/events.dart' as flame;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'chanceshfit_logic.dart';
import 'audio_manager.dart';

class BinaryBox extends flame.PositionComponent {
  bool isOne;
  Paint _paint;
  double _animationProgress = 0;
  bool _isAnimating = false;
  static const double _animationDuration = 0.3;
  final int number;
  final TextPainter _textPainter;

  BinaryBox({
    required super.position,
    required super.size,
    required this.isOne,
    required this.number,
  })  : _paint = Paint()
          ..color = isOne ? Colors.green : Colors.grey
          ..style = PaintingStyle.fill,
        _textPainter = TextPainter(
          text: TextSpan(
            text: number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        ) {
    _textPainter.layout();
  }

  void animateToNewState(bool newState) {
    _isAnimating = true;
    _animationProgress = 0;
    isOne = newState;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isAnimating) {
      _animationProgress += dt / _animationDuration;
      if (_animationProgress >= 1) {
        _animationProgress = 1;
        _isAnimating = false;
      }

      // Calculate intermediate color
      final startColor = _animationProgress < 0.5 ? Colors.grey : Colors.green;
      final endColor = _animationProgress < 0.5
          ? Colors.green
          : (isOne ? Colors.green : Colors.grey);
      final progress = _animationProgress < 0.5
          ? _animationProgress * 2
          : (_animationProgress - 0.5) * 2;

      _paint.color = Color.lerp(startColor, endColor, progress)!;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    // Add a glow effect when animating
    if (_isAnimating) {
      final glowPaint = Paint()
        ..color = _paint.color.withAlpha(76)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRect(
        Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
        glowPaint,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );

    // Center the text in the box
    _textPainter.paint(
      canvas,
      Offset(
        (size.x - _textPainter.width) / 2,
        (size.y - _textPainter.height) / 2,
      ),
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

class StartGame extends flame.FlameGame
    with flame.TapCallbacks, ChangeNotifier {
  final List<bool> binarySequence = List.generate(10, (_) => false);
  final TextEditingController _textController = TextEditingController();
  double _time = 0;
  final _random = math.Random();
  double _particleSpawnTimer = 0;
  static const double _particleSpawnInterval = 0.05;
  BuildContext? _context;
  Function(String)? onAnswerSubmitted;
  ChanceShiftLogic? _chanceShiftLogic;
  List<BinaryBox> _binaryBoxes = [];
  int _currentAnimationIndex = 0;
  double _animationDelay = 0;
  static const double _animationDelayDuration = 0.2;
  bool _isAnimating = false;
  final _audioManager = AudioManager();

  bool get isAnimating => _isAnimating;

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
      _audioManager.playWhoosh(); // Play whoosh sound when user submits answer
      final result = await _chanceShiftLogic!.query(input);
      // Start the sequential animation
      _currentAnimationIndex = 0;
      _animationDelay = 0;
      _isAnimating = true;
      notifyListeners(); // Notify listeners of animation state change

      // Store the new sequence
      for (int i = 0; i < binarySequence.length; i++) {
        binarySequence[i] = result["output"]![i] == 1;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _audioManager.initialize();

    // Clear existing boxes
    _binaryBoxes.clear();
    removeAll(children);

    // Add binary boxes
    final boxSize = flame.Vector2(40, 40);
    final spacing = 10.0;
    final startX = (size.x - boxSize.x) / 2; // Center horizontally
    final startY = size.y / 6; // Start from top 1/6 of the screen

    for (int i = 0; i < binarySequence.length; i++) {
      final position = flame.Vector2(
        startX,
        startY + (boxSize.y + spacing) * i,
      );

      final box = BinaryBox(
        position: position,
        size: boxSize,
        isOne: binarySequence[i],
        number: i + 1, // Add number from 1 to 10
      );
      _binaryBoxes.add(box);
      add(box);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _particleSpawnTimer += dt;

    // Handle sequential box animations
    if (_isAnimating) {
      _animationDelay += dt;
      if (_animationDelay >= _animationDelayDuration) {
        _animationDelay = 0;
        if (_currentAnimationIndex < _binaryBoxes.length) {
          final box = _binaryBoxes[_currentAnimationIndex];
          final newState = binarySequence[_currentAnimationIndex];
          box.animateToNewState(newState);
          if (newState) {
            _audioManager.playHit();
          }
          _currentAnimationIndex++;
        } else {
          _isAnimating = false;
          notifyListeners(); // Notify listeners of animation state change
        }
      }
    }

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
  String _prevPrevMessage = '';
  String _prevMessage = '';
  String _counterText = '0/50';
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _game = StartGame()
      ..setContext(context)
      ..setChanceShiftLogic(widget.chanceShiftLogic)
      ..setOnAnswerSubmitted(_handleAnswerSubmitted);

    _textController.addListener(() {
      setState(() {
        _counterText = '${_textController.text.length}/50';
      });
    });

    // Add animation state listener
    _game.addListener(() {
      if (_isAnimating != _game.isAnimating) {
        setState(() {
          _isAnimating = _game.isAnimating;
          if (_game.isAnimating) {
            _focusNode.unfocus(); // Unfocus keyboard when animation starts
          }
        });
      }
    });
  }

  void _handleAnswerSubmitted(String answer) {
    setState(() {
      _isAnimating = true;
    });
    _game.handleUserInput('Both $_prevMessage & $answer');
    _textController.clear();
    _focusNode.unfocus();
    setState(() {
      _prevPrevMessage = _prevMessage;
      _prevMessage = answer;
    });
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
                    child: AbsorbPointer(
                      absorbing: _isAnimating,
                      child: flame.GameWidget(
                        game: _game,
                      ),
                    ),
                  ),
                ),
                if (_prevPrevMessage.isEmpty && _prevMessage.isEmpty)
                  const SizedBox.shrink()
                else if (_prevPrevMessage.isEmpty)
                  Text(
                    _prevMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    '$_prevPrevMessage & $_prevMessage',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
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
                      if (_prevMessage.isNotEmpty && !_isAnimating)
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.4,
                          ),
                          child: Text(
                            '$_prevMessage & ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: _isAnimating,
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white),
                            maxLength: 50,
                            enabled: !_isAnimating,
                            decoration: InputDecoration(
                              hintText: _isAnimating
                                  ? 'Processing...'
                                  : 'Enter your answer...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              counterText: _counterText,
                              counterStyle: const TextStyle(color: Colors.grey),
                            ),
                            onSubmitted:
                                _isAnimating ? null : _handleAnswerSubmitted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AbsorbPointer(
                        absorbing: _isAnimating,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _isAnimating
                              ? null
                              : () {
                                  _handleAnswerSubmitted(_textController.text);
                                },
                        ),
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
                icon:
                    const Icon(Icons.volume_up, color: Colors.white, size: 32),
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
