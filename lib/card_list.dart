import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardInfo {
  final int idx;
  final int chanceValue;
  final int attackValue;
  final String name;
  final String description;

  CardInfo({
    required this.idx,
    required this.chanceValue,
    required this.attackValue,
    required this.name,
    required this.description,
  });

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo(
      idx: json['idx'],
      chanceValue: json['chance_value'],
      attackValue: json['attack_value'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idx': idx,
      'chance_value': chanceValue,
      'attack_value': attackValue,
      'name': name,
      'description': description,
    };
  }
}

class CardList {
  final List<CardInfo> cards;

  CardList({
    required this.cards,
  });

  factory CardList.fromJson(List<dynamic> parsedJson) {
    List<CardInfo> cards = parsedJson.map((i) => CardInfo.fromJson(i)).toList();
    return CardList(cards: cards);
  }

  List<dynamic> toJson() {
    return cards.map((i) => i.toJson()).toList();
  }
}

// A function to parse the JSON file
Future<CardList> parseCards(String jsonString) async {
  final jsonMap = jsonDecode(jsonString);
  final cardList = CardList.fromJson(jsonMap['cards']);
  return cardList;
}

Future<CardList> loadCardList() async {
  final String jsonString = await rootBundle.loadString('json/card_info.json');
  return parseCards(jsonString);
}

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CardListScreenState createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card List'),
      ),
      body: FutureBuilder<CardList>(
        future: loadCardList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.cards.length,
              itemBuilder: (context, index) {
                var card = snapshot.data!.cards[index];
                return ListTile(
                  title: Text(card.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(card.description),
                      Text("Attack Value: ${card.attackValue}"),
                      Text("Chance Value: ${card.chanceValue}"),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No cards found.'));
          }
        },
      ),
    );
  }
}
