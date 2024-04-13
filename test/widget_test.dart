import 'package:chanceshfit/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chanceshfit/game_interface.dart';

void main() {
  // Create a group for all related tests
  group('GameInterface tests', () {
    // Test to ensure the game initializes correctly
    testWidgets('Initial state is set correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: GameInterface()));
      // Verify initial conditions
      expect(find.text('Enemy HP: 5'), findsOneWidget);
      expect(find.text('Remaining Chances: 5'), findsOneWidget);
      expect(find.text('Chance Percent: 50'), findsOneWidget);
      expect(find.text('Attack Number: 1'), findsOneWidget);
    });

    // Test to ensure that the chance percentage increases with a card selection
    testWidgets('Selecting a card updates chance percentage and attack number',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: GameInterface()));
      // Assuming there's a way to mock or simulate loading card list
      await tester.pumpAndSettle(); // Wait for cards

      // Simulate selecting a card which increases chance by 10 and attack by 1
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump(); // Rebuild the widget with new state

      // Verify the changes
      expect(find.text('Chance Percent: 75'),
          findsOneWidget); // Assuming first card adds 25 to chance
      expect(find.text('Attack Number: 1'),
          findsOneWidget); // Assuming first card adds no change to attack
    });

    // Test to ensure that the 'Attack' button behaves correctly
    testWidgets('Performing an attack decreases chances and handles HP',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: GameInterface()));
      // Simulate an attack
      await tester.tap(find.widgetWithText(PushButton, 'Attack'));
      await tester.pump(); // Rebuild the widget to reflect state changes

      // Verify the results of an attack
      expect(find.text('Remaining Chances: 4'),
          findsOneWidget); // Chances decrease by 1
      // Check SnackBar for attack result, assuming random attack success
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
