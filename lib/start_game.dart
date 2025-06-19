import 'package:flame/game.dart' as flame;
import 'package:flame/components.dart' as flame;
import 'package:flame/events.dart' as flame;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'chanceshfit_logic.dart';
import 'audio_manager.dart';
import 'dart:async';

// =============================================================================
// GAME ENUMS AND CONSTANTS
// =============================================================================

/// Available game pattern choices
enum GameChoice { even, odd, custom, wild }

/// Game configuration constants
class GameConfig {
  static const int sequenceLength = 10;
  static const double boxSize = 40.0;
  static const double boxSpacing = 10.0;
  static const double animationDuration = 0.3;
  static const double animationDelayDuration = 0.2;
  static const double particleSpawnInterval = 0.05;
  static const int particlesPerSpawn = 5;
  static const double particleLifetimeMin = 2.0;
  static const double particleLifetimeMax = 5.0;
  static const double particleVelocityHorizontal = 150.0;
  static const double particleVelocityVerticalMin = 100.0;
  static const double particleVelocityVerticalMax = 400.0;
  static const double particleRadiusMin = 1.0;
  static const double particleRadiusMax = 3.0;
  static const double particleOpacity = 0.7;
  static const double glowBlurRadius = 10.0;
  static const double glowAlpha = 76.0;
}

// =============================================================================
// WILD SEQUENCE PATTERNS
// =============================================================================

/// Predefined mathematical sequences for the wild choice
class WildSequences {
  static const Map<String, List<int>> sequences = {
    'Fibonacci': [1, 1, 0, 1, 1, 0, 0, 1, 0, 0], // 1,2,3,5,8 in 10-bit
    'Prime Numbers': [0, 1, 1, 0, 1, 0, 1, 0, 0, 0], // 2,3,5,7 in first 10
    'Perfect Squares': [1, 0, 0, 1, 0, 0, 0, 0, 1, 0], // 1,4,9 in first 10
    'Powers of 2': [1, 1, 0, 1, 0, 0, 0, 1, 0, 0], // 1,2,4,8 in first 10
    'Lucky Numbers': [1, 0, 1, 0, 0, 0, 1, 0, 1, 0], // 1,3,7,9
  };

  /// Returns a random wild sequence
  static MapEntry<String, List<int>> getRandom() {
    final keys = sequences.keys.toList();
    final randomKey = keys[math.Random().nextInt(keys.length)];
    return MapEntry(randomKey, sequences[randomKey]!);
  }
}

// =============================================================================
// CUSTOM MESSAGE EXAMPLES
// =============================================================================

/// Example custom messages for user guidance
class CustomMessageExamples {
  static const List<String> examples = [
    'numbers divisible by 3',
    'perfect squares',
    'prime numbers',
  ];

  /// Returns a random example message
  static String getRandom() {
    return examples[math.Random().nextInt(examples.length)];
  }
}

// =============================================================================
// ANIMATION UTILITIES
// =============================================================================

// =============================================================================
// GAME COMPONENTS
// =============================================================================

/// A visual box representing a binary digit (0 or 1)
class BinaryBox extends flame.PositionComponent {
  bool isOne;
  Paint _paint;
  double _animationProgress = 0;
  bool _isAnimating = false;
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

  /// Animates the box to a new state (0 or 1)
  void animateToNewState(bool newState) {
    _isAnimating = true;
    _animationProgress = 0;
    isOne = newState;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isAnimating) {
      _animationProgress += dt / GameConfig.animationDuration;
      if (_animationProgress >= 1) {
        _animationProgress = 1;
        _isAnimating = false;
      }

      _updateAnimationColor();
    }
  }

  /// Updates the color during animation
  void _updateAnimationColor() {
    final startColor = _animationProgress < 0.5 ? Colors.grey : Colors.green;
    final endColor = _animationProgress < 0.5
        ? Colors.green
        : (isOne ? Colors.green : Colors.grey);
    final progress = _animationProgress < 0.5
        ? _animationProgress * 2
        : (_animationProgress - 0.5) * 2;

    _paint.color = Color.lerp(startColor, endColor, progress)!;
  }

  @override
  void render(ui.Canvas canvas) {
    _renderGlowEffect(canvas);
    _renderBox(canvas);
    _renderText(canvas);
  }

  /// Renders the glow effect during animation
  void _renderGlowEffect(ui.Canvas canvas) {
    if (_isAnimating) {
      final glowPaint = Paint()
        ..color = _paint.color.withAlpha(GameConfig.glowAlpha.round())
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, GameConfig.glowBlurRadius);
      canvas.drawRect(
        Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
        glowPaint,
      );
    }
  }

  /// Renders the main box
  void _renderBox(ui.Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }

  /// Renders the number text centered in the box
  void _renderText(ui.Canvas canvas) {
    _textPainter.paint(
      canvas,
      Offset(
        (size.x - _textPainter.width) / 2,
        (size.y - _textPainter.height) / 2,
      ),
    );
  }
}

/// A particle that moves upward with fade-out effect
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

    _updateOpacity();
    _checkLifetime();
  }

  /// Updates particle opacity based on lifetime
  void _updateOpacity() {
    final progress = (_time / lifetime).clamp(0.0, 1.0);
    final opacity = (1 - progress) * GameConfig.particleOpacity;
    paint.color = Colors.white.withAlpha((opacity * 255).round());
  }

  /// Removes particle when lifetime expires
  void _checkLifetime() {
    if (_time >= lifetime) {
      removeFromParent();
    }
  }
}

// =============================================================================
// MAIN GAME CLASS
// =============================================================================

/// The main game class that manages the binary sequence visualization
class StartGame extends flame.FlameGame
    with flame.TapCallbacks, ChangeNotifier {
  // Game state
  final List<bool> binarySequence =
      List.generate(GameConfig.sequenceLength, (_) => false);
  final List<BinaryBox> _binaryBoxes = [];
  final _audioManager = AudioManager();

  // Animation state
  bool _isAnimating = false;
  int _currentAnimationIndex = 0;
  double _animationDelay = 0;

  // Particle system
  final _random = math.Random();
  double _particleSpawnTimer = 0;

  // Game logic
  ChanceShiftLogic? _chanceShiftLogic;
  Function(GameChoice, {String? wildSequenceName})? onChoiceSelected;

  // UI state
  BuildContext? _context;
  String _customMessage = '';
  String _lastChoice = '';
  String _lastInputText = '';
  String _userFriendlyText = '';

  // Getters
  bool get isAnimating => _isAnimating;
  String get lastChoice => _lastChoice;
  String get customMessage => _customMessage;
  String get lastInputText => _lastInputText;
  String get userFriendlyText => _userFriendlyText;

  // ===========================================================================
  // SETUP METHODS
  // ===========================================================================

  void setContext(BuildContext context) {
    _context = context;
  }

  void setChanceShiftLogic(ChanceShiftLogic logic) {
    _chanceShiftLogic = logic;
  }

  void setCustomMessage(String message) {
    _customMessage = message;
  }

  void setOnChoiceSelected(
      Function(GameChoice, {String? wildSequenceName}) callback) {
    onChoiceSelected = callback;
  }

  // ===========================================================================
  // TEXT GENERATION
  // ===========================================================================

  /// Generates user-friendly text describing the current choice
  String _generateUserFriendlyText(GameChoice choice,
      {String? wildSequenceName}) {
    final currentChoice = _getChoiceDescription(choice, wildSequenceName);

    if (_lastChoice.isNotEmpty) {
      return 'Combining $_lastChoice with $currentChoice...';
    } else {
      return 'Looking for $currentChoice...';
    }
  }

  /// Gets a human-readable description of a game choice
  String _getChoiceDescription(GameChoice choice, String? wildSequenceName) {
    switch (choice) {
      case GameChoice.even:
        return 'even numbers';
      case GameChoice.odd:
        return 'odd numbers';
      case GameChoice.custom:
        return _customMessage;
      case GameChoice.wild:
        return wildSequenceName?.toLowerCase() ?? 'random pattern';
    }
  }

  // ===========================================================================
  // GAME LOGIC
  // ===========================================================================

  /// Handles a user's pattern choice
  Future<void> handleChoice(GameChoice choice,
      {String? wildSequenceName}) async {
    if (_chanceShiftLogic == null) return;
    print('handleChoice: $choice, $wildSequenceName');

    // For wild choice, we need to await the animation to get the selected sequence name
    if (choice == GameChoice.wild && wildSequenceName == null) {
      wildSequenceName = await _showWildSelectionDialog();
      if (wildSequenceName == null) return; // User cancelled or animation failed
    }
    print('after wild selection dialog');

    // Reset animation state to ensure clean state
    _resetAnimationState();

    _audioManager.playWhoosh();
    _setUserFriendlyText(choice, wildSequenceName);

    final choiceData = _prepareChoiceData(choice, wildSequenceName);
    final result = await _processChoice(choiceData);

    _updateGameState(choice, result, wildSequenceName);
    _startAnimation();
  }

  /// Sets the user-friendly text and notifies listeners
  void _setUserFriendlyText(GameChoice choice, String? wildSequenceName) {
    _userFriendlyText =
        _generateUserFriendlyText(choice, wildSequenceName: wildSequenceName);
    notifyListeners();
  }

  /// Prepares the data needed for processing a choice
  Map<String, dynamic> _prepareChoiceData(
      GameChoice choice, String? wildSequenceName) {
    String inputText = '';
    List<int>? directSequence;
    bool useLLM = false;

    switch (choice) {
      case GameChoice.even:
        if (_lastChoice.isNotEmpty) {
          inputText =
              'Generate a binary sequence that satisfies BOTH conditions: $_lastChoice AND even numbers. The result should be a superset or combination of both patterns.';
          useLLM = true;
        } else {
          inputText = 'even numbers';
          directSequence = [
            0,
            1,
            0,
            1,
            0,
            1,
            0,
            1,
            0,
            1
          ]; // positions 2,4,6,8,10
        }
        break;
      case GameChoice.odd:
        if (_lastChoice.isNotEmpty) {
          inputText =
              'Generate a binary sequence that satisfies BOTH conditions: $_lastChoice AND odd numbers. The result should be a superset or combination of both patterns.';
          useLLM = true;
        } else {
          inputText = 'odd numbers';
          directSequence = [
            1,
            0,
            1,
            0,
            1,
            0,
            1,
            0,
            1,
            0
          ]; // positions 1,3,5,7,9
        }
        break;
      case GameChoice.custom:
        if (_lastChoice.isNotEmpty) {
          inputText =
              'Generate a binary sequence that satisfies BOTH conditions: $_lastChoice AND $_customMessage. The result should be a superset or combination of both patterns.';
        } else {
          inputText = _customMessage;
        }
        useLLM = true;
        break;
      case GameChoice.wild:
        if (wildSequenceName != null &&
            WildSequences.sequences.containsKey(wildSequenceName)) {
          if (_lastChoice.isNotEmpty) {
            inputText =
                'Generate a binary sequence that satisfies BOTH conditions: $_lastChoice AND ${wildSequenceName.toLowerCase()}. The result should be a superset or combination of both patterns.';
            useLLM = true;
          } else {
            inputText = wildSequenceName.toLowerCase();
            directSequence = WildSequences.sequences[wildSequenceName];
          }
        } else {
          // Always use LLM if wildSequenceName is missing or invalid
          if (_lastChoice.isNotEmpty) {
            inputText =
                'Generate a binary sequence that satisfies BOTH conditions: $_lastChoice AND a random mathematical pattern. The result should be a superset or combination of both patterns.';
          } else {
            inputText = 'a random mathematical pattern';
          }
          useLLM = true;
        }
        break;
    }

    // Fallback: ensure inputText is never empty
    if (inputText.trim().isEmpty) {
      inputText = 'a random mathematical pattern';
      useLLM = true;
    }

    return {
      'inputText': inputText,
      'directSequence': directSequence,
      'useLLM': useLLM,
    };
  }

  /// Processes the choice using AI or direct sequence
  Future<Map<String, List<int>>> _processChoice(
      Map<String, dynamic> choiceData) async {
    final inputText = choiceData['inputText'] as String;
    final directSequence = choiceData['directSequence'] as List<int>?;
    final useLLM = choiceData['useLLM'] as bool;

    _lastInputText = inputText;

    if (useLLM || directSequence == null) {
      return await _chanceShiftLogic!.query(inputText);
    } else {
      return {"output": directSequence};
    }
  }

  /// Updates the game state with the new sequence
  void _updateGameState(GameChoice choice, Map<String, List<int>> result,
      String? wildSequenceName) {
    // Update binary sequence
    for (int i = 0; i < binarySequence.length; i++) {
      binarySequence[i] = result["output"]![i] == 1;
    }

    // Update last choice name
    _lastChoice = _getChoiceName(choice, wildSequenceName);
  }

  /// Gets the display name for a choice
  String _getChoiceName(GameChoice choice, String? wildSequenceName) {
    switch (choice) {
      case GameChoice.even:
        return 'Even Numbers';
      case GameChoice.odd:
        return 'Odd Numbers';
      case GameChoice.custom:
        return 'Custom: ${_customMessage}';
      case GameChoice.wild:
        return wildSequenceName ?? 'Wild';
    }
  }

  /// Resets the animation state to ensure clean state
  void _resetAnimationState() {
    _isAnimating = false;
    _currentAnimationIndex = 0;
    _animationDelay = 0;
    notifyListeners();
  }

  /// Starts the sequential animation
  void _startAnimation() {
    _currentAnimationIndex = 0;
    _animationDelay = 0;
    _isAnimating = true;
    notifyListeners();
  }

  // ===========================================================================
  // GAME LIFECYCLE
  // ===========================================================================

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _audioManager.initialize();
    _setupBinaryBoxes();
  }

  /// Sets up the binary boxes in the game
  void _setupBinaryBoxes() {
    _binaryBoxes.clear();
    removeAll(children);

    final boxSize = flame.Vector2(GameConfig.boxSize, GameConfig.boxSize);
    final startX = (size.x - boxSize.x) / 2; // Center horizontally
    final startY = size.y / 6; // Start from top 1/6 of the screen

    for (int i = 0; i < binarySequence.length; i++) {
      final position = flame.Vector2(
        startX,
        startY + (boxSize.y + GameConfig.boxSpacing) * i,
      );

      final box = BinaryBox(
        position: position,
        size: boxSize,
        isOne: binarySequence[i],
        number: i + 1,
      );
      _binaryBoxes.add(box);
      add(box);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _particleSpawnTimer += dt;

    _updateAnimation(dt);
    _updateParticleSystem(dt);
  }

  /// Updates the sequential box animation
  void _updateAnimation(double dt) {
    if (!_isAnimating) return;

    _animationDelay += dt;
    if (_animationDelay >= GameConfig.animationDelayDuration) {
      _animationDelay = 0;
      _processNextAnimationStep();
    }
  }

  /// Processes the next step in the animation sequence
  void _processNextAnimationStep() {
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
      notifyListeners();
    }
  }

  /// Updates the particle system
  void _updateParticleSystem(double dt) {
    while (_particleSpawnTimer >= GameConfig.particleSpawnInterval) {
      _particleSpawnTimer -= GameConfig.particleSpawnInterval;
      _spawnParticles();
    }
  }

  /// Spawns multiple particles for visual effect
  void _spawnParticles() {
    for (int i = 0; i < GameConfig.particlesPerSpawn; i++) {
      final particle = _createParticle();
      add(particle);
    }
  }

  /// Creates a single particle with random properties
  MovingParticle _createParticle() {
    return MovingParticle(
      position: flame.Vector2(
        _random.nextDouble() * size.x,
        size.y + 10, // Start slightly below the screen
      ),
      velocity: flame.Vector2(
        (_random.nextDouble() - 0.5) * GameConfig.particleVelocityHorizontal,
        -_random.nextDouble() *
                (GameConfig.particleVelocityVerticalMax -
                    GameConfig.particleVelocityVerticalMin) -
            GameConfig.particleVelocityVerticalMin,
      ),
      lifetime: _random.nextDouble() *
              (GameConfig.particleLifetimeMax -
                  GameConfig.particleLifetimeMin) +
          GameConfig.particleLifetimeMin,
      radius: _random.nextDouble() *
              (GameConfig.particleRadiusMax - GameConfig.particleRadiusMin) +
          GameConfig.particleRadiusMin,
      paint: Paint()
        ..color = Colors.white.withOpacity(GameConfig.particleOpacity),
    );
  }

  /// Shows the wild selection dialog and returns the selected sequence name
  Future<String?> _showWildSelectionDialog() async {
    if (_context == null) return null;

    final options = WildSequences.sequences.keys.toList();
    final random = math.Random();
    int currentIndex = random.nextInt(options.length); // random start
    int baseIterations = 20;
    int totalIterations = baseIterations + random.nextInt(5) - 2; // 18~22
    int iteration = 0;
    StateSetter? setDialogState;
    bool isBlinking = false;
    int blinkCount = 0;
    double blinkOpacity = 1.0;

    // Create a completer to return the result
    final completer = Completer<String?>();

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          setDialogState = setState;
          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 12,
            title: const Text(
              '🎲 Random Selection! 🎲',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The arrow will slow down and pick for you!',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: options.asMap().entries.map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            final isSelected = index == currentIndex;
                            final isBlink = isSelected && isBlinking;
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: isBlink ? blinkOpacity : 1.0,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color: Colors.yellow.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.yellow, width: 2),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    if (isSelected)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          '→',
                                          style: TextStyle(
                                            color: Colors.yellow,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.yellow
                                              : Colors.white,
                                          fontSize: isSelected ? 18 : 15,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    void startBlinking() {
      isBlinking = true;
      blinkCount = 0;
      blinkOpacity = 0.2;
      void doBlink() {
        if (!_context!.mounted || setDialogState == null) return;
        setDialogState!(() {
          blinkOpacity = blinkOpacity == 1.0 ? 0.2 : 1.0;
        });
        blinkCount++;
        if (blinkCount < 6) {
          Future.delayed(const Duration(milliseconds: 120), doBlink);
        } else {
          Navigator.of(_context!).pop();
          // Complete the future with the selected option
          if (!completer.isCompleted) {
            completer.complete(options[currentIndex]);
          }
        }
      }

      doBlink();
    }

    void animate() {
      if (iteration >= totalIterations) {
        startBlinking();
        return;
      }
      final progress = iteration / totalIterations;
      final delay = (1500 / totalIterations) *
          (1 + progress * 4); // 1.5 seconds total, exponential slowdown
      Future.delayed(Duration(milliseconds: delay.round()), () {
        if (_context!.mounted && setDialogState != null) {
          currentIndex = (currentIndex + 1) % options.length;
          iteration++;
          setDialogState!(() {});
          animate();
        } else {
          // Handle case where context is no longer mounted
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      });
    }

    animate();
    
    // Return the future that will complete when animation finishes
    return completer.future;
  }

  @override
  void onRemove() {
    super.onRemove();
  }
}

// =============================================================================
// UI COMPONENTS
// =============================================================================

/// The main game page widget
class StartGamePage extends StatefulWidget {
  final ChanceShiftLogic chanceShiftLogic;

  const StartGamePage({super.key, required this.chanceShiftLogic});

  @override
  State<StartGamePage> createState() => _StartGamePageState();
}

class _StartGamePageState extends State<StartGamePage> {
  late StartGame _game;
  final _audioManager = AudioManager();
  final TextEditingController _customMessageController =
      TextEditingController();

  // UI state
  bool _isAnimating = false;
  bool _hasSetCustomMessage = false;
  bool _isMuted = true;
  String? _selectedExample;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupAudioState();
    _setupAnimationListener();
  }

  /// Initializes the game instance
  void _initializeGame() {
    _game = StartGame()
      ..setContext(context)
      ..setChanceShiftLogic(widget.chanceShiftLogic)
      ..setOnChoiceSelected(_handleChoiceSelected);
  }

  /// Sets up the initial audio state
  void _setupAudioState() {
    _isMuted = _audioManager.isMuted;
  }

  /// Sets up the animation state listener
  void _setupAnimationListener() {
    _game.addListener(() {
      setState(() {
        _isAnimating = _game.isAnimating;
      });
    });
  }

  // ===========================================================================
  // EVENT HANDLERS
  // ===========================================================================

  void _handleChoiceSelected(GameChoice choice, {String? wildSequenceName}) async {
    if (_isAnimating) return; // Prevent double-tap
    setState(() {
      _isAnimating = true;
    });
    await _game.handleChoice(choice, wildSequenceName: wildSequenceName);
  }

  void _setCustomMessage() {
    setState(() {
      _hasSetCustomMessage = _customMessageController.text.trim().isNotEmpty;
      _game.setCustomMessage(_customMessageController.text.trim());
    });
    _customMessageController.clear();
  }

  void _selectExample(String example) {
    setState(() {
      _selectedExample = example;
      _customMessageController.text = example;
      _hasSetCustomMessage = true;
      _game.setCustomMessage(example);
    });
  }

  // ===========================================================================
  // UI BUILDING
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainContent(),
            _buildAudioToggle(),
          ],
        ),
      ),
    );
  }

  /// Builds the main game content
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildGameArea(),
        _buildUserFriendlyText(),
        _buildCustomMessageSection(),
        _buildGameControls(),
      ],
    );
  }

  /// Builds the game area with the Flame game widget
  Widget _buildGameArea() {
    return Expanded(
      child: AbsorbPointer(
        absorbing: _isAnimating,
        child: flame.GameWidget(game: _game),
      ),
    );
  }

  /// Builds the user-friendly text display
  Widget _buildUserFriendlyText() {
    if (_game.userFriendlyText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        _game.userFriendlyText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the custom message input section
  Widget _buildCustomMessageSection() {
    if (_hasSetCustomMessage) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Set your custom message:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildCustomMessageInput(),
          const SizedBox(height: 8),
          _buildExampleButtons(),
        ],
      ),
    );
  }

  /// Builds the custom message input field
  Widget _buildCustomMessageInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customMessageController,
            style: const TextStyle(color: Colors.white),
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'Enter your custom message...',
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _setCustomMessage(),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _setCustomMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: const Text('Set'),
        ),
      ],
    );
  }

  /// Builds the example buttons
  Widget _buildExampleButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: CustomMessageExamples.examples.map((example) {
          final isSelected = _selectedExample == example;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectExample(example),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withOpacity(0.8)
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green
                            : Colors.grey.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[300],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Builds the game control buttons
  Widget _buildGameControls() {
    if (!_hasSetCustomMessage) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.8),
      padding: const EdgeInsets.all(16),
      child: AbsorbPointer(
        absorbing: _isAnimating,
        child: Column(
          children: [
            const Text(
              'Choose your pattern:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildPatternButtons(),
          ],
        ),
      ),
    );
  }

  /// Builds the pattern selection buttons
  Widget _buildPatternButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                    _buildPatternButton('Even', Colors.blue, GameChoice.even)),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _buildPatternButton('Odd', Colors.purple, GameChoice.odd)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCustomPatternButton()),
            const SizedBox(width: 8),
            Expanded(
                child: _buildPatternButton('Wild', Colors.red, GameChoice.wild)),
          ],
        ),
      ],
    );
  }

  /// Builds a standard pattern button
  Widget _buildPatternButton(String text, Color color, GameChoice choice,
      {VoidCallback? onPressed}) {
    final isDisabled = _isAnimating;
    return ElevatedButton(
      onPressed:
          isDisabled ? null : onPressed ?? () => _handleChoiceSelected(choice),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? color.withOpacity(0.4) : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: const Size(0, 48),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
      ),
    );
  }

  /// Builds the custom pattern button
  Widget _buildCustomPatternButton() {
    final isDisabled = _isAnimating;
    return ElevatedButton(
      onPressed:
          isDisabled ? null : () => _handleChoiceSelected(GameChoice.custom),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDisabled ? Colors.orange.withOpacity(0.4) : Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        minimumSize: const Size(0, 48),
      ),
      child: Text(
        _game.customMessage.isNotEmpty ? _game.customMessage : 'Custom',
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        maxLines: 2,
      ),
    );
  }

  /// Builds the audio toggle button
  Widget _buildAudioToggle() {
    return Positioned(
      top: 16,
      right: 16,
      child: IconButton(
        icon: Icon(
          _isMuted ? Icons.volume_off : Icons.volume_up,
          color: Colors.white,
          size: 32,
        ),
        onPressed: () async {
          await _audioManager.toggleMute();
          setState(() {
            _isMuted = _audioManager.isMuted;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }
}
