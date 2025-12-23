import '../models/movie_model.dart';

class RecommendationEngine {
  static final _stopWords = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'of',
    'in',
    'on',
    'for',
    'with',
    'to'
  };

  /// Tokenize and normalize a string
  static List<String> _tokens(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .toList();
  }

  /// Recommend movies for a free-text user query using simple token scoring.
  /// This is a lightweight fallback that combines tag overlap and title matches
  /// to reduce overly literal behavior.
  static List<Movie> recommendForQuery(List<Movie> movies, String query,
      {int limit = 50}) {
    final queryTokens = _tokens(query);
    if (queryTokens.isEmpty) return [];

    final scores = <Movie, int>{};

    for (final m in movies) {
      int score = 0;
      final title = m.title.toLowerCase();
      final tags = m.tags.toLowerCase();
      final movieTokens = _tokens('${m.title} ${m.tags}');

      for (final qt in queryTokens) {
        // strong match if token appears in tags
        if (tags.contains(qt)) score += 3;

        // medium match if token appears in title
        if (title.contains(qt)) score += 2;

        // weak match if token appears in any movie token (partial)
        if (movieTokens.any((mt) => mt.contains(qt))) score += 1;
      }

      if (score > 0) scores[m] = score;
    }

    final sorted = scores.keys.toList()
      ..sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));

    return sorted.toList(); // Return ALL results, not limited to 50
  }

  /// Recommendations by genre (keeps compatibility with older callers)
  /// Now includes intelligent fallback to related genres
  static List<Movie> recommendByGenre(List<Movie> movies, String genre) {
    genre = genre.toLowerCase().trim();

    // First, try exact match
    var results =
        movies.where((m) => m.tags.toLowerCase().contains(genre)).toList();

    // If not enough results, add related movies from broader searches
    if (results.length < 30) {
      // Add movies that have related keywords
      final relatedKeywords = _getRelatedKeywords(genre);
      for (final keyword in relatedKeywords) {
        final related = movies.where((m) {
          final tags = m.tags.toLowerCase();
          return tags.contains(keyword) &&
              !results.any((r) => r.id == m.id); // Avoid duplicates
        }).toList();
        results.addAll(related);

        if (results.length >= 150) break; // Collect enough before filtering
      }
    }

    // If still not enough, add high-quality movies from general search
    if (results.length < 30) {
      final topMovies = movies
          .where((m) =>
              m.posterUrl.isNotEmpty && !results.any((r) => r.id == m.id))
          .toList();
      results.addAll(topMovies);
    }

    return results.toList();
  }

  /// Get related keywords for a genre to improve result diversity
  static List<String> _getRelatedKeywords(String genre) {
    final relatedMap = {
      'action': [
        'adventur',
        'fight',
        'battl',
        'explos',
        'chas',
        'hero',
        'superhero',
        'thriller',
        'crime'
      ],
      'comedy': ['funny', 'humor', 'laugh', 'witty', 'sarcas', 'parodi'],
      'drama': [
        'emot',
        'deep',
        'serious',
        'tragic',
        'conflict',
        'relationship'
      ],
      'horror': [
        'scary',
        'fear',
        'ghost',
        'zombie',
        'monster',
        'supernatural',
        'terror'
      ],
      'sci-fi': [
        'space',
        'futur',
        'robot',
        'alien',
        'tech',
        'sci',
        'cyborg',
        'dystopi',
        'apocalyp'
      ],
      'romance': [
        'love',
        'romantic',
        'lover',
        'relationship',
        'passion',
        'intimate'
      ],
      'thriller': [
        'suspense',
        'mystery',
        'dark',
        'tense',
        'crime',
        'psycho',
        'twist'
      ],
      'adventure': [
        'adventur',
        'explorer',
        'quest',
        'journey',
        'travel',
        'expedit',
        'action'
      ],
      'fantasy': [
        'magical',
        'magic',
        'wizard',
        'dragon',
        'knight',
        'enchant',
        'mythical'
      ],
      'animation': [
        'animat',
        'anime',
        'cartoon',
        'family',
        'colorful',
        'bright'
      ],
      'family': [
        'family',
        'kids',
        'children',
        'wholesome',
        'innocent',
        'fun',
        'animation'
      ],
      'crime': [
        'crime',
        'detective',
        'police',
        'gangster',
        'mafia',
        'theft',
        'murder',
        'thriller'
      ],
      'documentary': [
        'document',
        'real',
        'biograph',
        'history',
        'factual',
        'nature',
        'wildlife'
      ],
    };

    return relatedMap[genre] ?? [];
  }

  /// Recommendations similar to a given movie using tag overlap and scoring.
  static List<Movie> recommendSimilar(List<Movie> movies, String movieName,
      {int limit = 50}) {
    movieName = movieName.toLowerCase().trim();

    // Find the base movie (best match) with better matching logic
    Movie? base;
    int bestMatchScore = 0;

    for (final m in movies) {
      final titleLower = m.title.toLowerCase();
      int matchScore = 0;

      // Exact match
      if (titleLower == movieName) {
        matchScore = 100;
      }
      // Starts with
      else if (titleLower.startsWith(movieName)) {
        matchScore = 50;
      }
      // Contains full word
      else if (titleLower.contains(' $movieName') ||
          titleLower.contains('$movieName ')) {
        matchScore = 30;
      }
      // Contains substring
      else if (titleLower.contains(movieName)) {
        matchScore = 20;
      }
      // Check tags
      else if (m.tags.toLowerCase().contains(movieName)) {
        matchScore = 15;
      }

      if (matchScore > bestMatchScore) {
        bestMatchScore = matchScore;
        base = m;
      }
    }

    // If no movie found, use fallback
    base ??= movies.isNotEmpty ? movies.first : null;

    if (base == null) {
      return [];
    }

    final baseTokens = _tokens('${base.title} ${base.tags}');
    final scores = <Movie, int>{};

    for (final m in movies) {
      if (m.id == base.id) continue;
      int score = 0;
      final tokens = _tokens('${m.title} ${m.tags}');

      for (final t in baseTokens) {
        if (tokens.contains(t)) {
          score += 3;
        } else if (tokens.any((mt) => mt.contains(t))) {
          score += 1;
        }
      }

      if (score > 0) scores[m] = score;
    }

    final sorted = scores.keys.toList()
      ..sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));

    return sorted.toList(); // Return ALL results
  }
}
