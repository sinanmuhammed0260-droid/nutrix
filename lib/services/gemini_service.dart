import 'dart:typed_data';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('API_KEY');
  late final GenerativeModel _model;

  GeminiService() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini API key not found. Pass it using --dart-define=API_KEY=YOUR_KEY',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 400,
      ),
    );
  }

  /// Analyze food image + user allergies
  /// Returns:
  /// {
  ///   "item": "apple",
  ///   "safe": true,
  ///   "allergen": null,
  ///   "explanation": "..."
  /// }
  Future<Map<String, dynamic>> analyzeFoodImage({
    required Uint8List imageBytes,
    required List<String> userAllergies,
  }) async {
    try {
      final prompt = '''
You are a food allergy analysis system.

User allergies:
${userAllergies.isEmpty ? 'None' : userAllergies.join(', ')}

Tasks:
1. Identify the food item in the image.
2. Check for possible allergic reactions.
3. Respond ONLY with valid JSON. No markdown. No explanation outside JSON.

JSON format:
{
  "item": "food name or unknown",
  "safe": true or false,
  "allergen": "name or null",
  "explanation": "short clear reason"
}
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/*', imageBytes), // safer than hardcoding jpeg
        ])
      ];

      final response = await _model.generateContent(content);

      final rawText = response.text;
      if (rawText == null || rawText.isEmpty) {
        throw Exception('Empty AI response');
      }

      // Clean response (in case Gemini adds formatting)
      final cleanedText = rawText
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '');

      return json.decode(cleanedText) as Map<String, dynamic>;
    } on GenerativeAIException catch (e) {
      return {
        "item": "unknown",
        "safe": false,
        "allergen": null,
        "explanation": "AI Error: ${e.message}",
      };
    } catch (e) {
      return {
        "item": "unknown",
        "safe": false,
        "allergen": null,
        "explanation": "Unexpected error: $e",
      };
    }
  }

  /// Text-only nutrition or allergy questions
  Future<String> askNutritionQuestion(String prompt) async {
    final response =
    await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'No response received.';
  }
}