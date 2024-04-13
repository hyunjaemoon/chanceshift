import 'package:flutter/material.dart';

class TutorialWidget extends StatelessWidget {
  const TutorialWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'images/game_logo.png',
          width: 70,
          height: 70,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to ChanceShift!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'In this game, you have to defeat the enemy by performing attacks. Here\'s how the game interface works:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildStep(
                'Enemy HP',
                'This shows the current health points of the enemy. You need to reduce it to 0 to win the game.',
              ),
              const SizedBox(height: 8),
              _buildStep(
                'Remaining Chances',
                'This indicates the number of chances you have left to perform attacks. If it reaches 0, you lose the game.',
              ),
              const SizedBox(height: 8),
              _buildStep(
                'Chance Percent',
                'This represents the probability of a successful attack. The higher the chance percent, the more likely your attack will succeed.',
              ),
              const SizedBox(height: 8),
              _buildStep(
                'Attack Number',
                'This determines the number of attacks you perform in each turn. The higher the attack number, the more damage you can deal to the enemy.',
              ),
              const SizedBox(height: 8),
              const Text(
                'To play the game, follow these steps:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildStep(
                '1. Adjust the values',
                'You can adjust the values of Enemy HP, Remaining Chances, Chance Percent, and Attack Number by tapping the "+" button next to each value.',
              ),
              const SizedBox(height: 8),
              _buildStep(
                '2. Select cards',
                'You can select up to 3 cards from the available options. Each card provides additional chance percent and attack number.',
              ),
              const SizedBox(height: 8),
              _buildStep(
                '3. Perform an attack',
                'Tap the "Perform Attack" button to perform the attacks. The game will calculate the success or failure of each attack based on the chance percent.',
              ),
              const SizedBox(height: 16),
              const Text(
                'That\'s it! You can now start playing ChanceShift. Good luck!',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
