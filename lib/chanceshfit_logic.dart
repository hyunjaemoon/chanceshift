import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChanceShiftLogic {
  final ImagenModel? imageModel;
  final GenerativeModel? generativeModel;
  final String? apiKey; // For direct API access

  ChanceShiftLogic({
    this.imageModel,
    this.generativeModel,
    this.apiKey,
  });

  Future<Map<String, List<int>>> query(String userInput) async {
    try {
      // Try Firebase AI first if available
      if (generativeModel != null) {
        return await _queryWithFirebase(userInput);
      }

      // Fallback to direct API if Firebase AI is not available
      if (apiKey != null) {
        return await _queryWithDirectAPI(userInput);
      }

      // If neither is available, return default pattern
      print('No AI service available, using default pattern');
      return {
        "output": [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
      };
    } catch (e) {
      print('Error generating output binary: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      // Return a default pattern
      return {
        "output": [0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
      };
    }
  }

  Future<Map<String, List<int>>> _queryWithFirebase(String userInput) async {
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

    print('Sending prompt to Firebase AI: $prompt');

    // Get response from the generative model
    final response = await generativeModel!.generateContent(
      [
        Content.text(prompt),
      ],
      generationConfig: GenerationConfig(
        temperature: 0,
      ),
    );

    return _processResponse(response.text ?? '');
  }

  Future<Map<String, List<int>>> _queryWithDirectAPI(String userInput) async {
    final prompt = '''
    You are a binary sequence generator. Generate exactly 10 binary digits (0s and 1s) based on this input: '$userInput'
    
    Rules: Output only 10 digits, no other text. For example: 1010101010
    ''';

    print('Sending prompt to direct API: $prompt');

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.0,
          'maxOutputTokens': 50,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] ?? '';
      return _processResponse(text);
    } else {
      throw Exception('API request failed with status: ${response.statusCode}');
    }
  }

  Map<String, List<int>> _processResponse(String outputStr) {
    print('Raw AI response: $outputStr');

    // Clean the response to get only binary digits
    outputStr = outputStr.replaceAll(RegExp(r'[^01]'), '');
    print('Cleaned binary string: $outputStr');

    // Ensure we have exactly 10 digits
    List<int> outputBinary = List<int>.filled(10, 0);
    for (int i = 0; i < min(outputStr.length, 10); i++) {
      outputBinary[i] = int.parse(outputStr[i]);
    }

    print('Final binary sequence: $outputBinary');

    return {
      "output": outputBinary,
    };
  }

  int min(int a, int b) => a < b ? a : b;
}
