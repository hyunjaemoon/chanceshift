import 'dart:convert';
import 'dart:math';

import 'package:chanceshfit/card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChanceShift',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
      ),
      home: GameInterface(),
    );
  }
}

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
        title: Text('ChanceShift'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView(
                children: [
                  _buildStatCard('Chance Percent', chancePercent, (newValue) {
                    setState(() => chancePercent = newValue);
                  }),
                  _buildStatCard('Attack Number', attackNum, (newValue) {
                    setState(() => attackNum = newValue);
                  }),
                  _buildStatCard('Enemy HP', enemyHp, (newValue) {
                    setState(() => enemyHp = newValue);
                  }),
                  _buildStatCard('Remaining Chances', remainingChances,
                      (newValue) {
                    setState(() => remainingChances = newValue);
                  }),
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
                    child: Text('View Cards'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _performAttack,
              child: Text('Attack!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, ValueChanged<int> onChanged) {
    return Card(
      child: ListTile(
        title: Text('$label: $value'),
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
            label: Text(cards.cards[cardIndex].name),
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
    // Dummy logic for an attack
    if (remainingChances > 0 && enemyHp > 0) {
      setState(() {
        for (int i = 0; i < attackNum; i++) {
          if (chancePercent >= 100 || chancePercent >= Random().nextInt(100)) {
            enemyHp -= 1;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attack Success!'),
                duration: Duration(seconds: 1), // Duration can be adjusted
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attack Failed...'),
                duration: Duration(seconds: 1), // Duration can be adjusted
              ),
            );
          }
        }
        remainingChances--;
      });
    }
    // Perform other game logic like checking for win/lose conditions
    if (enemyHp == 0) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('You win!'),
            content: Text('You defeated the enemy!'),
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
            content: Text('You ran out of chances!'),
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
  }
}
