import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class ChanceShiftLogic {
  final ImagenModel imageModel;
  final GenerativeModel generativeModel;

  ChanceShiftLogic({
    required this.imageModel,
    required this.generativeModel,
  });

  Future<Map<String, List<int>>> query(String userInput) async {
    try {
      // Create a prompt for the generative model
      final prompt = '''
      You are a binary sequence generator that converts user input into a meaningful sequence of numbers from 1 to 10.

      Rules:
      1. You must output exactly ONE binary sequence of length 10
      2. Each position in the sequence represents a number from 1 to 10 (left to right)
      3. Use 1 to indicate a selected number and 0 for unselected numbers
      4. The sequence should reflect meaningful patterns or themes from the input
      5. If the input is empty, unclear, or doesn't suggest any pattern, generate an alternating sequence
      6. You can select multiple numbers if the input suggests multiple relevant choices
      7. The output should be a single line of 10 binary digits (0s and 1s)

      Input to analyze: '$userInput'

      Number representation in the sequence:
      Position 1: 1000000000 (One)
      Position 2: 0100000000 (Two)
      Position 3: 0010000000 (Three)
      Position 4: 0001000000 (Four)
      Position 5: 0000100000 (Five)
      Position 6: 0000010000 (Six)
      Position 7: 0000001000 (Seven)
      Position 8: 0000000100 (Eight)
      Position 9: 0000000010 (Nine)
      Position 10: 0000000001 (Ten)

      Example outputs:
      - For "happy": 0000001000 (Seven, representing luck)
      - For "love": 0000000100 (Eight, representing infinity)
      - For empty input: 1010101010 (Alternating pattern)
      - For "success": 0000100000 (Five, representing balance)
      - For "none": 0000000000 (All zeros)
      - For "all": 1111111111 (All ones)

      Generate your sequence now:
      ''';

      // Get response from the generative model
      final response = await generativeModel.generateContent(
        [
          Content.text(prompt),
        ],
        generationConfig: GenerationConfig(
          temperature: 0,
        ),
      );

      // Extract the binary sequence from the response
      String outputStr = response.text ?? '';
      print('Output string: $outputStr');
      // Clean the response to get only binary digits
      outputStr = outputStr.replaceAll(RegExp(r'[^01]'), '');

      // Ensure we have exactly 10 digits
      List<int> outputBinary = List<int>.filled(10, 0);
      for (int i = 0; i < min(outputStr.length, 10); i++) {
        outputBinary[i] = int.parse(outputStr[i]);
      }

      return {
        "output": outputBinary,
      };
    } catch (e) {
      // In case of error, return a default pattern
      print('Error generating output binary: $e');
      return {
        "output": [0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
      };
    }
  }

  int min(int a, int b) => a < b ? a : b;
}
