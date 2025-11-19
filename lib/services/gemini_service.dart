import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService({String? apiKey})
      : _apiKey = apiKey ??
            const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String?> generateDishImage(String dishName) async {
    if (!isConfigured) return null;

    final prompt =
        'Create a high-resolution, appetizing food photography image of $dishName, shot on a clean plate with soft lighting.';

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'responseMimeType': 'image/png',
          },
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = body['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final inlineData = parts.first['inlineData'] as Map<String, dynamic>?;
            final data = inlineData?['data'] as String?;
            if (data != null && data.isNotEmpty) {
              return 'data:image/png;base64,$data';
            }
          }
        }
      } else {
        debugPrint('Gemini image error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini image generation failed: $e');
    }
    return null;
  }
}




