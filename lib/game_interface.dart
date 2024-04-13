import 'dart:math';

import 'package:chanceshfit/card_list.dart';
import 'package:chanceshfit/ui.dart';
import 'package:flutter/material.dart';

const defaultTextStyle = TextStyle(fontSize: 25);

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

class _GameInterfaceState extends State<GameInterface> {
  late int chancePercent;
  late int attackNum;
  late int enemyHp;
  late int remainingChances;
  List<int> cardIndices = [];
  Future<CardList>? cardsFuture;

  bool _isPerformingAttack = false;

  void reset() {
    setState(() {
      chancePercent = widget.initialChancePercent;
      attackNum = widget.initialAttackNum;
      enemyHp = widget.initialEnemyHp;
      remainingChances = widget.initialRemainingChances;
      cardIndices = [];
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChanceShift v0.1', style: defaultTextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    children:
                        List.generate(3, (index) => _buildCardSelector(index)),
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
                  PushButton(onPressed: _performAttack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, ValueChanged<int> onChanged) {
    return Card(
      child: ListTile(
        title: Text('$label: $value', style: defaultTextStyle),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            onChanged(value + 1);
          },
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
          return FilterChip(
            selected: isSelected,
            label: Text(cards.cards[cardIndex].name,
                style: TextStyle(fontSize: 18)),
            onSelected: (bool selected) {
              setState(() {
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

  void _performAttack() {
    if (_isPerformingAttack) return;

    setState(() {
      _isPerformingAttack = true;
    });

    // Dummy logic for an attack
    if (remainingChances > 0 && enemyHp > 0) {
      setState(() {
        remainingChances--;
        for (int i = 0; i < attackNum; i++) {
          if (chancePercent >= 100 || chancePercent >= Random().nextInt(100)) {
            enemyHp -= 1;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attack Success!', style: defaultTextStyle),
                duration: Duration(seconds: 1), // Duration can be adjusted
              ),
            );
          } else {
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
        }
      });
    }
    // Perform other game logic like checking for win/lose conditions
    if (enemyHp == 0) {
      showDialog(
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
      _isPerformingAttack = false;
    });
  }
}
