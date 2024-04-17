import 'dart:math';

import 'package:chanceshfit/card_display.dart';
import 'package:chanceshfit/card_list.dart';
import 'package:chanceshfit/slash.dart';
import 'package:chanceshfit/ui.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

const defaultTextStyle = TextStyle(fontSize: 25);

const totalCardNumber = 4;

class GameInterface extends StatefulWidget {
  final int initialChancePercent;
  final int initialAttackNum;
  final int initialEnemyHp;
  final int initialRemainingChances;

  const GameInterface({
    super.key,
    this.initialChancePercent = 50, // Default value if not provided
    this.initialAttackNum = 1,
    this.initialEnemyHp = 5,
    this.initialRemainingChances = 5,
  });

  @override
  // ignore: library_private_types_in_public_api
  _GameInterfaceState createState() => _GameInterfaceState();
}

class _GameInterfaceState extends State<GameInterface>
    with SingleTickerProviderStateMixin {
  late int chancePercent;
  late int attackNum;
  late int enemyHp;
  late int remainingChances;
  List<int> cardIndices = [];
  Set<int> usedCardIndices = {};
  Future<CardList>? cardsFuture;

  final AudioPlayer _audioPlayer = AudioPlayer();

  AnimationController? _controller;
  // ignore: unused_field
  Animation<double>? _shakeAnimation;

  bool _isPerformingAttack = false;

  void reset() {
    setState(() {
      chancePercent = widget.initialChancePercent;
      attackNum = widget.initialAttackNum;
      enemyHp = widget.initialEnemyHp;
      remainingChances = widget.initialRemainingChances;
      cardIndices = [];
      usedCardIndices = {};
    });
  }

  @override
  void initState() {
    super.initState();
    cardsFuture = loadCardList();
    chancePercent = widget.initialChancePercent;
    attackNum = widget.initialAttackNum;
    enemyHp = widget.initialEnemyHp;
    remainingChances = widget.initialRemainingChances;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(_controller!)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller!.reverse();
        }
      });
  }

  @override
  void dispose() {
    _controller!.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void startShake() {
    _controller!.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    double offsetX =
        sin(_controller!.value * pi * 10) * (_controller!.value * 10);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'images/game_logo.png',
          width: 70,
          height: 70,
        ),
        centerTitle: true,
      ),
      body: Transform.translate(
        offset: Offset(offsetX, 0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  children: [
                    _buildStatCard('Enemy HP', enemyHp, (newValue) {
                      setState(() => enemyHp = newValue);
                    }),
                    StatusBar(
                        value: enemyHp,
                        maxValue: widget.initialEnemyHp,
                        color: Colors.red),
                    _buildStatCard('Remaining Chances', remainingChances,
                        (newValue) {
                      setState(() => remainingChances = newValue);
                    }),
                    StatusBar(
                        value: remainingChances,
                        maxValue: widget.initialRemainingChances,
                        color: Colors.blue),
                    _buildStatCard('Chance Percent', max(0, chancePercent),
                        (newValue) {
                      setState(() => chancePercent = newValue);
                    }),
                    StatusBar(
                        value: max(0, chancePercent),
                        maxValue: 100,
                        color: Colors.green),
                    _buildStatCard('Attack Number', attackNum, (newValue) {
                      setState(() => attackNum = newValue);
                    }),
                    SwordIconsRow(numIcons: attackNum),
                    Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: List.generate(totalCardNumber,
                          (index) => _buildCardSelector(index)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to CardListScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CardListScreen()),
                        );
                      },
                      child: const Text('View Cards', style: defaultTextStyle),
                    ),
                  ],
                ),
              ),
              PushButton(
                onPressed: _performAttack,
                isPerformingAttack: _isPerformingAttack,
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, ValueChanged<int> onChanged) {
    return Card(
      child: ListTile(
        title: Text('$label: $value', style: defaultTextStyle),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }

  Widget _buildCardSelector(int cardIndex) {
    return FutureBuilder<CardList>(
      future: cardsFuture,
      builder: (BuildContext context, AsyncSnapshot<CardList> snapshot) {
        if (snapshot.hasData) {
          var cards = snapshot.data!;
          bool isSelected = cardIndices.contains(cards.cards[cardIndex].idx);
          return CardDisplay(
            selected: isSelected,
            used: usedCardIndices.contains(cards.cards[cardIndex].idx),
            cardInfo: cards.cards[cardIndex],
            onSelected: (bool selected) {
              setState(() {
                if (usedCardIndices.contains(cards.cards[cardIndex].idx)) {
                  return;
                }
                if (selected) {
                  cardIndices.add(cards.cards[cardIndex].idx);
                  chancePercent += cards.cards[cardIndex].chanceValue;
                  attackNum += cards.cards[cardIndex].attackValue;
                } else {
                  cardIndices.remove(cards.cards[cardIndex].idx);
                  chancePercent -= cards.cards[cardIndex].chanceValue;
                  attackNum -= cards.cards[cardIndex].attackValue;
                }
              });
            },
          );
        } else if (snapshot.hasError) {
          return const Text("Error loading cards.");
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  void _performAttack() async {
    if (_isPerformingAttack) return;

    if (attackNum <= 0) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot attack with 0 Attack Number!',
            style: defaultTextStyle,
          ),
          duration: Duration(seconds: 1), // Duration can be adjusted
        ),
      );
      return;
    }

    setState(() {
      _isPerformingAttack = true;
    });

    // Add all the selected cards to usedCardIndices
    usedCardIndices.addAll(cardIndices);

    // Dummy logic for an attack
    if (remainingChances > 0 && enemyHp > 0) {
      setState(() {
        remainingChances--;
      });
      while (attackNum > 0) {
        setState(() {
          attackNum--;
        });
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => const SlashAnimation(),
        );
        await Future.delayed(const Duration(
            seconds: 1, milliseconds: 500)); // Add a delay of 500 milliseconds
        if (chancePercent >= 100 || chancePercent >= Random().nextInt(100)) {
          // Play Hit Audio
          await _audioPlayer.setAsset('audio/whoosh.wav');
          _audioPlayer.play();

          // Shake the screen
          startShake();
          setState(() {
            enemyHp -= 1;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attack Success!', style: defaultTextStyle),
              duration: Duration(seconds: 1), // Duration can be adjusted
            ),
          );
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Attack Failed...',
                style: defaultTextStyle,
              ),
              duration: Duration(seconds: 1), // Duration can be adjusted
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
        if (enemyHp <= 0) {
          break;
        }
      }
    }
    // Perform other game logic like checking for win/lose conditions
    if (enemyHp <= 0) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('You win!'),
            content: const Text('You defeated the enemy!',
                style: TextStyle(fontSize: 18)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  reset();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else if (remainingChances == 0) {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Game Over'),
            content: const Text('You ran out of chances!',
                style: TextStyle(fontSize: 18)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  reset();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    setState(() {
      chancePercent = widget.initialChancePercent;
      attackNum = widget.initialAttackNum;
      _isPerformingAttack = false;
    });
  }
}
