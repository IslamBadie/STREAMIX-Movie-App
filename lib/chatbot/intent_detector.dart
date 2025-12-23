class IntentDetector {
  static String detectIntent(String message) {
    message = message.toLowerCase();

    // Similar movie patterns (English)
    if (message.contains('like') ||
        message.contains('similar') ||
        message.contains('similar to') ||
        message.contains('similarity') ||
        message.contains('comparable to') ||
        message.contains('along the lines of') ||
        message.contains('remind me of') ||
        message.contains('along') ||
        message.contains('comparable')) {
      return 'similar_movie';
    }

    // Similar movie patterns (Arabic)
    if (message.contains('مثل') ||
        message.contains('تشابه') ||
        message.contains('شبيه') ||
        message.contains('مشابه') ||
        message.contains('يشبه') ||
        message.contains('مثلا') ||
        message.contains('مثله') ||
        message.contains('أفلام مثل')) {
      return 'similar_movie';
    }

    // Genre recommendation patterns (English) - more comprehensive
    if (message.contains('movie') ||
        message.contains('movies') ||
        message.contains('recommend') ||
        message.contains('suggest') ||
        message.contains('i want') ||
        message.contains('i like') ||
        message.contains('i would like') ||
        message.contains('recommend me') ||
        message.contains('show me') ||
        message.contains('give me') ||
        message.contains('find me') ||
        message.contains('what should') ||
        message.contains('show') ||
        message.contains('find') ||
        message.contains('search')) {
      return 'genre_recommend';
    }

    // Genre recommendation patterns (Arabic)
    if (message.contains('فيلم') ||
        message.contains('أفلام') ||
        message.contains('أوصني') ||
        message.contains('أوصني') ||
        message.contains('أريد') ||
        message.contains('أحب') ||
        message.contains('أحب') ||
        message.contains('أوصي') ||
        message.contains('أرني') ||
        message.contains('أعطني') ||
        message.contains('ابحث') ||
        message.contains('ابحث') ||
        message.contains('البحث') ||
        message.contains('عن') ||
        message.contains('اقترح') ||
        message.contains('اقترح')) {
      return 'genre_recommend';
    }

    // If message is very short (2-5 words) and no clear action word, might be a raw movie name
    final words = message.trim().split(RegExp(r'\s+'));
    if (words.length <= 5 &&
        words.isNotEmpty &&
        !_hasActionWords(message) &&
        _seemsLikeMovieName(message)) {
      return 'raw_movie_or_genre';
    }

    return 'unknown';
  }

  static bool _hasActionWords(String message) {
    return message.contains('recommend') ||
        message.contains('suggest') ||
        message.contains('want') ||
        message.contains('like') ||
        message.contains('find') ||
        message.contains('show') ||
        message.contains('give') ||
        message.contains('search') ||
        message.contains('أوصني') ||
        message.contains('أريد') ||
        message.contains('أحب') ||
        message.contains('ابحث') ||
        message.contains('اقترح');
  }

  static bool _seemsLikeMovieName(String message) {
    // Has capital letters or known movie patterns
    return message.contains(RegExp(r'[A-Z]')) ||
        message.length > 2 ||
        message.split(' ').length <= 5;
  }

  static String? extractGenre(String message, Map<String, String> genreMap) {
    // Use provided genreMap to detect genre in message
    message = message.toLowerCase().trim();

    // Check keys (possible synonyms) first
    for (var key in genreMap.keys) {
      if (message.contains(key.toLowerCase())) {
        return genreMap[key];
      }
    }

    // Check mapped values (standard genre names)
    for (var value in genreMap.values) {
      if (message.contains(value.toLowerCase())) {
        return value;
      }
    }

    return null;
  }
}
