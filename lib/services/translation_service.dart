import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for translating movie descriptions using Google Translate API
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();

  factory TranslationService() => _instance;

  TranslationService._internal();
  final Map<String, String> _cache = {};

  /// Translate text from English to Arabic using Google Translate API
  /// Returns the translated text or the original text if translation fails
  Future<String> translateToArabic(String text) async {
    if (text.isEmpty || text.length < 10) {
      return text; // Don't translate short texts
    }

    // Return cached translation if available
    if (_cache.containsKey(text)) return _cache[text]!;

    try {
      // Using Google Translate API endpoint (free tier)
      // Format: https://translate.googleapis.com/translate_a/element.js?
      final encodedText = Uri.encodeComponent(text);
      final url =
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ar&dt=t&q=$encodedText';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Translation timeout'),
          );

      if (response.statusCode == 200) {
        try {
          // Parse the response - Google returns nested array structure
          final List<dynamic> decoded = jsonDecode(response.body);
          if (decoded.isNotEmpty && decoded[0] is List) {
            final List<dynamic> translations = decoded[0];
            String result = '';
            for (var item in translations) {
              if (item is List && item.isNotEmpty) {
                result += item[0]?.toString() ?? '';
              }
            }
            if (result.isNotEmpty) {
              // Cache and return
              _cache[text] = result;
              return result;
            }
          }
        } catch (_) {
          // If parsing fails, return original
          return text;
        }
      }
      return text;
    } catch (e) {
      // On any error, return original text
      return text;
    }
  }

  /// Batch translate multiple texts (more efficient)
  Future<Map<String, String>> translateMultiple(
    List<String> texts,
  ) async {
    final Map<String, String> results = {};

    for (String text in texts) {
      if (text.isEmpty) {
        results[text] = text;
      } else if (_cache.containsKey(text)) {
        results[text] = _cache[text]!;
      } else {
        final t = await translateToArabic(text);
        results[text] = t;
        // Add small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
