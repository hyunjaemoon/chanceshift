import 'dart:math';

import 'package:chanceshfit/card_list.dart';
import 'package:chanceshfit/ui.dart';
import 'package:flutter/material.dart';

const defaultTextStyle = TextStyle(fontSize: 25);

class GameInterface extends StatefulWidget {
  @override
  _GameInterfaceState createState() => _GameInterfaceState();
}

class _GameInterfaceState extends State<GameInterface> {
  int chancePercent = 50;
  int attackNum = 1;
  int enemyHp = 5;
  int remainingChances = 5;
  List<int> cardIndices = [];
  Future<CardList>? cardsFuture;

  bool _isPerformingAttack = false;

  void reset() {
    setState(() {
      chancePercent = 50;
      attackNum = 1;
      enemyHp = 5;
      remainingChances = 5;
      cardIndices = [];
    });
  }

  @override
  void initState() {
    super.initState();
    cardsFuture = loadCardList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChanceShift v0.1', style: defaultTextStyle),
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
                  StatusBar(value: enemyHp, maxValue: 5, color: Colors.red),
                  _buildStatCard('Remaining Chances', remainingChances,
                      (newValue) {
                    setState(() => remainingChances = newValue);
                  }),
                  StatusBar(
                      value: remainingChances, maxValue: 5, color: Colors.blue),
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
                            builder: (context) => CardListScreen()),
                      );
                    },
                    child: Text('View Cards', style: defaultTextStyle),
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
          icon: Icon(Icons.add),
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
          return Text("Error loading cards.");
        } else {
          return CircularProgressIndicator();
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
              SnackBar(
                content: Text('Attack Success!', style: defaultTextStyle),
                duration: Duration(seconds: 1), // Duration can be adjusted
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
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
            title: Text('You win!'),
            content:
                Text('You defeated the enemy!', style: TextStyle(fontSize: 18)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  reset();
                },
                child: Text('OK'),
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
            title: Text('Game Over'),
            content:
                Text('You ran out of chances!', style: TextStyle(fontSize: 18)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  reset();
                },
                child: Text('OK'),
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
