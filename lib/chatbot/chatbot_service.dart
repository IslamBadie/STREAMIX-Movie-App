import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/movie_model.dart';
import 'intent_detector.dart';
import 'recommendation_engine.dart';
import '../config/api_config.dart';

class ChatBotService {
  List<Movie> _movies = [];
  List<Movie> _lastRecommendations = [];
  Map<String, dynamic> _similarityData = {};

  /// Genre map for detection (supports common English names)
  final Map<String, String> _genreMap = {
    // Action movies
    'action': 'action',
    'fight': 'action',
    'fighting': 'action',
    'battle': 'action',
    'combat': 'action',
    'explosion': 'action',
    'explosions': 'action',
    'shoot': 'action',
    'shooting': 'action',
    'gun': 'action',
    'guns': 'action',
    'weapon': 'action',
    'weapons': 'action',
    'chase': 'action',
    'chasing': 'action',
    'superhero': 'action',
    'hero': 'action',
    'heroic': 'action',
    'superheros': 'action',
    'adrenaline': 'action',

    // Adventure
    'adventure': 'adventure',
    'adventurous': 'adventure',
    'explorer': 'adventure',
    'exploration': 'adventure',
    'expedition': 'adventure',
    'quest': 'adventure',
    'journey': 'adventure',
    'travel': 'adventure',

    // Horror/Scary
    'horror': 'horror',
    'scary': 'horror',
    'fear': 'horror',
    'frightening': 'horror',
    'creepy': 'horror',
    'terrifying': 'horror',
    'terror': 'horror',
    'ghost': 'horror',
    'ghosts': 'horror',
    'zombie': 'horror',
    'zombies': 'horror',
    'monster': 'horror',
    'monsters': 'horror',
    'demon': 'horror',
    'demons': 'horror',
    'evil': 'horror',
    'curse': 'horror',
    'blood': 'horror',
    'gore': 'horror',
    'haunted': 'horror',
    'supernatural': 'horror',
    'spine': 'horror',
    'chilling': 'horror',

    // Sci-Fi
    'sci-fi': 'sci-fi',
    'sci fi': 'sci-fi',
    'science fiction': 'sci-fi',
    'scifi': 'sci-fi',
    'space': 'sci-fi',
    'futuristic': 'sci-fi',
    'future': 'sci-fi',
    'tech': 'sci-fi',
    'technology': 'sci-fi',
    'technological': 'sci-fi',
    'cyber': 'sci-fi',
    'cyberpunk': 'sci-fi',
    'robot': 'sci-fi',
    'robots': 'sci-fi',
    'alien': 'sci-fi',
    'aliens': 'sci-fi',
    'ufo': 'sci-fi',
    'spaceship': 'sci-fi',
    'spacecraft': 'sci-fi',
    'time travel': 'sci-fi',
    'time': 'sci-fi',
    'dimension': 'sci-fi',
    'parallel': 'sci-fi',
    'apocalypse': 'sci-fi',
    'apocalyptic': 'sci-fi',
    'dystopian': 'sci-fi',
    'dystopia': 'sci-fi',
    'utopia': 'sci-fi',
    'utopian': 'sci-fi',
    'cybernetic': 'sci-fi',
    'AI': 'sci-fi',
    'artificial intelligence': 'sci-fi',
    'android': 'sci-fi',
    'androids': 'sci-fi',

    // Romance
    'romance': 'romance',
    'love': 'romance',
    'romantic': 'romance',
    'lover': 'romance',
    'lovers': 'romance',
    'relationship': 'romance',
    'relationships': 'romance',
    'couple': 'romance',
    'couples': 'romance',
    'kiss': 'romance',
    'kissing': 'romance',
    'intimate': 'romance',
    'intimacy': 'romance',
    'passion': 'romance',
    'passionate': 'romance',
    'heartfelt': 'romance',
    'tender': 'romance',
    'sweet': 'romance',

    // Comedy
    'comedy': 'comedy',
    'funny': 'comedy',
    'humor': 'comedy',
    'humorous': 'comedy',
    'laugh': 'comedy',
    'laughing': 'comedy',
    'hilarious': 'comedy',
    'comic': 'comedy',
    'comic relief': 'comedy',
    'joke': 'comedy',
    'jokes': 'comedy',
    'silly': 'comedy',
    'slapstick': 'comedy',
    'witty': 'comedy',
    'wit': 'comedy',
    'sarcasm': 'comedy',
    'sarcastic': 'comedy',
    'satire': 'comedy',
    'parody': 'comedy',
    'spoof': 'comedy',
    'pun': 'comedy',
    'lighthearted': 'comedy',
    'fun': 'comedy',
    'cheerful': 'comedy',
    'gag': 'comedy',

    // Drama
    'drama': 'drama',
    'emotional': 'drama',
    'emotion': 'drama',
    'deep': 'drama',
    'serious': 'drama',
    'tension': 'drama',
    'conflict': 'drama',
    'betrayal': 'drama',
    'tragedy': 'drama',
    'tragic': 'drama',
    'sad': 'drama',
    'sadness': 'drama',
    'melancholy': 'drama',
    'heartbreak': 'drama',
    'heartbroken': 'drama',
    'pain': 'drama',
    'suffering': 'drama',
    'struggle': 'drama',
    'challenging': 'drama',
    'powerful': 'drama',
    'touching': 'drama',
    'moving': 'drama',
    'compelling': 'drama',
    'gripping': 'drama',
    'character': 'drama',
    'characters': 'drama',

    // Thriller
    'thriller': 'thriller',
    'suspense': 'thriller',
    'suspenseful': 'thriller',
    'mystery': 'thriller',
    'mysterious': 'thriller',
    'psycho': 'thriller',
    'psychological': 'thriller',
    'dark': 'thriller',
    'darkness': 'thriller',
    'tense': 'thriller',
    'twist': 'thriller',
    'twist ending': 'thriller',
    'shocking': 'thriller',
    'shock': 'thriller',
    'murder': 'thriller',
    'killer': 'thriller',
    'investigate': 'thriller',
    'investigation': 'thriller',
    'detective story': 'thriller',

    // Crime
    'crime': 'crime',
    'criminal': 'crime',
    'detective': 'crime',
    'police': 'crime',
    'cop': 'crime',
    'cops': 'crime',
    'gangster': 'crime',
    'mafia': 'crime',
    'gang': 'crime',
    'gangs': 'crime',
    'heist': 'crime',
    'robbery': 'crime',
    'rob': 'crime',
    'theft': 'crime',
    'thief': 'crime',
    'thieves': 'crime',
    'killing': 'crime',
    'dead': 'crime',
    'corpse': 'crime',
    'law': 'crime',
    'court': 'crime',
    'judge': 'crime',
    'prison': 'crime',
    'jail': 'crime',

    // Fantasy
    'fantasy': 'fantasy',
    'magical': 'fantasy',
    'magic': 'fantasy',
    'wizard': 'fantasy',
    'wizards': 'fantasy',
    'sorcerer': 'fantasy',
    'witch': 'fantasy',
    'witches': 'fantasy',
    'spell': 'fantasy',
    'spells': 'fantasy',
    'enchanted': 'fantasy',
    'enchantment': 'fantasy',
    'dragon': 'fantasy',
    'dragons': 'fantasy',
    'knight': 'fantasy',
    'knights': 'fantasy',
    'sword': 'fantasy',
    'swords': 'fantasy',
    'castle': 'fantasy',
    'castles': 'fantasy',
    'kingdom': 'fantasy',
    'kingdoms': 'fantasy',
    'mythical': 'fantasy',
    'myth': 'fantasy',
    'legendary': 'fantasy',
    'legend': 'fantasy',
    'fantasy world': 'fantasy',

    // Animation
    'animation': 'animation',
    'animated': 'animation',
    'anime': 'animation',
    'cartoon': 'animation',
    'cartoons': 'animation',
    'colorful': 'animation',
    'bright': 'animation',
    'vibrant': 'animation',

    // Family
    'family': 'family',
    'kids': 'family',
    'children': 'family',
    'child': 'family',
    'kid': 'family',
    'wholesome': 'family',
    'child-friendly': 'family',
    'kid-friendly': 'family',
    'innocent': 'family',

    // Documentary
    'documentary': 'documentary',
    'doc': 'documentary',
    'real': 'documentary',
    'reality': 'documentary',
    'true': 'documentary',
    'biographical': 'documentary',
    'biography': 'documentary',
    'history': 'documentary',
    'fact': 'documentary',
    'factual': 'documentary',
    'educational': 'documentary',
    'nature': 'documentary',
    'wild': 'documentary',
    'wildlife': 'documentary',
    'animals': 'documentary',
    'science': 'documentary',

    // Historical
    'historical': 'historical',
    'period': 'historical',
    'old': 'historical',
    'ancient': 'historical',
    'era': 'historical',
    'Victorian': 'historical',
    'medieval': 'historical',

    // War
    'war': 'war',
    'military': 'war',
    'soldier': 'war',
    'soldiers': 'war',
    'army': 'war',
    'battles': 'war',
    'world war': 'war',
    'ww1': 'war',
    'ww2': 'war',
    'wwii': 'war',

    // Western
    'western': 'western',
    'cowboy': 'western',
    'cowboys': 'western',
    'saloon': 'western',
    'outlaw': 'western',
    'outlaws': 'western',
    'sheriff': 'western',
    'outback': 'western',

    // Sports
    'sports': 'sports',
    'sport': 'sports',
    'basketball': 'sports',
    'football': 'sports',
    'soccer': 'sports',
    'boxing': 'sports',
    'ball': 'sports',
    'balls': 'sports',
    'race': 'sports',
    'racing': 'sports',
    'athlete': 'sports',
    'athletes': 'sports',
    'team': 'sports',
    'teams': 'sports',
    'game': 'sports',
    'games': 'sports',
    'championship': 'sports',
    'tournament': 'sports',
    'competitive': 'sports',
    'competition': 'sports',
    'olympic': 'sports',
    'olympics': 'sports',
  };

  List<Movie> get lastRecommendations => _lastRecommendations;

  Future<void> loadData() async {
    try {
      final data =
          await rootBundle.loadString('assets/model_ai/movie_data.json');
      final List decoded = json.decode(data);
      _movies = decoded.map((e) => Movie.fromJson(e)).toList();

      // Load similarity data for AI-based recommendations
      await _loadSimilarityData();

      // Fetch images from API for each movie
      await _enrichMoviesWithImages();

      debugPrint('✅ Loaded ${_movies.length} movies from database');
      debugPrint(
          '✅ Loaded AI similarity data for ${_similarityData.length} movies');
    } catch (e) {
      debugPrint('❌ Error loading movie data: $e');
    }
  }

  /// Load similarity data from AI model
  Future<void> _loadSimilarityData() async {
    try {
      final data =
          await rootBundle.loadString('assets/model_ai/similarity_data.json');
      _similarityData = json.decode(data) as Map<String, dynamic>;
      debugPrint(
          '✅ Similarity data loaded for ${_similarityData.length} movies');
    } catch (e) {
      debugPrint('❌ Error loading similarity data: $e');
    }
  }

  /// Enrich movies with poster images from TMDB API
  Future<void> _enrichMoviesWithImages() async {
    final apiKey = ApiConfig.effectiveTmdbApiKey;
    if (apiKey.isEmpty) {
      debugPrint('⚠️ TMDB API key not configured, skipping image enrichment');
      return;
    }

    for (int i = 0; i < _movies.length; i++) {
      final movie = _movies[i];
      if (movie.posterUrl.isEmpty) {
        try {
          // Use TMDB search to find movie
          final response = await http
              .get(
                Uri.parse(
                    '${ApiConfig.tmdbBaseUrl}/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(movie.title)}&page=1'),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final results = data['results'] as List?;
            if (results != null && results.isNotEmpty) {
              final movieData = results.first as Map<String, dynamic>;
              final posterPath = movieData['poster_path'] as String?;
              final voteAverage = movieData['vote_average'] as num?;
              final releaseDate = movieData['release_date'] as String?;

              // Get poster URL with proper TMDB image URL construction
              String posterUrl = '';
              if (posterPath != null && posterPath.isNotEmpty) {
                posterUrl = 'https://image.tmdb.org/t/p/w342$posterPath';
              }

              // Extract year from release date
              int year = 0;
              if (releaseDate != null && releaseDate.isNotEmpty) {
                try {
                  year = int.parse(releaseDate.split('-').first);
                } catch (_) {
                  year = movie.year;
                }
              }

              _movies[i] = Movie(
                id: movieData['id'] ?? movie.id,
                title: movie.title,
                tags: movie.tags,
                rating: (voteAverage?.toDouble() ??
                    0), // TMDB ratings are 0-10, keep as is
                year: year > 0 ? year : movie.year,
                runtime: movie.runtime,
                genres: (movieData['genre_ids'] as List?)
                        ?.map((g) => g.toString())
                        .toList() ??
                    movie.genres,
                posterUrl: posterUrl,
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch poster for ${movie.title}: $e');
        }
      }
    }
  }

  /// Detect if input is in Arabic
  bool _isArabic(String text) {
    // Check for Arabic Unicode ranges
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  Future<String> reply(String message) async {
    final isArabic = _isArabic(message);
    final intent = IntentDetector.detectIntent(message);

    // Handle raw movie name or genre (no explicit action words)
    if (intent == 'raw_movie_or_genre') {
      final genre = IntentDetector.extractGenre(message, _genreMap);

      // If it's recognized as a genre, treat it as genre recommendation
      if (genre != null) {
        return await _handleGenreRecommendationAsync(genre, message,
            isArabic: isArabic);
      }

      // Otherwise, try to find as a movie name or similar movies
      return await _handleSimilarMovieAsync(message, isArabic: isArabic);
    }

    if (intent == 'genre_recommend') {
      return await _handleGenreRecommendationAsync(message, message,
          isArabic: isArabic);
    }

    if (intent == 'similar_movie') {
      return await _handleSimilarMovieAsync(message, isArabic: isArabic);
    }

    _lastRecommendations = [];
    return isArabic
        ? 'لم أفهم. جرب: "أوصني بفيلم أكشن" أو "أفلام مثل Inception"'
        : 'I did not understand. Try: "Recommend an action movie" or "Movies similar to Inception"';
  }

  /// Asynchronously enrich recommendations with TMDB posters
  /// This should be called after getting initial recommendations
  Future<void> enrichLastRecommendationsWithPosters() async {
    if (_lastRecommendations.isEmpty) return;

    debugPrint(
        '🔄 Starting async poster enrichment for ${_lastRecommendations.length} movies...');

    // Run enrichment in background
    _lastRecommendations = await _enrichMoviesWithPosters(_lastRecommendations);

    debugPrint(
        '✅ Enrichment complete! Now have ${_lastRecommendations.length} movies');
  }

  /// Async version of genre recommendation with poster enrichment
  Future<String> _handleGenreRecommendationAsync(
      String genre, String originalMessage,
      {bool isArabic = false}) async {
    // Get recommendations (sync)
    String result =
        _handleGenreRecommendation(genre, originalMessage, isArabic: isArabic);

    // Enrich with TMDB posters (async)
    if (_lastRecommendations.isNotEmpty) {
      debugPrint(
          '🔄 Enriching ${_lastRecommendations.length} recommendations with TMDB posters...');
      _lastRecommendations =
          await _enrichMoviesWithPosters(_lastRecommendations);
      debugPrint(
          '✅ Enrichment done! ${_lastRecommendations.length} movies now ready');
    }

    return result;
  }

  /// Async version of similar movie recommendation with poster enrichment
  Future<String> _handleSimilarMovieAsync(String message,
      {bool isArabic = false}) async {
    // Get recommendations (sync)
    String result = _handleSimilarMovie(message, isArabic: isArabic);

    // Enrich with TMDB posters (async)
    if (_lastRecommendations.isNotEmpty) {
      debugPrint(
          '🔄 Enriching ${_lastRecommendations.length} recommendations with TMDB posters...');
      _lastRecommendations =
          await _enrichMoviesWithPosters(_lastRecommendations);
      debugPrint(
          '✅ Enrichment done! ${_lastRecommendations.length} movies now ready');
    }

    return result;
  }

  String _formatMovies(List<Movie> movies, {bool isArabic = false}) {
    if (movies.isEmpty) {
      return isArabic
          ? 'لا توجد توصيات متاحة في الوقت الحالي.'
          : 'No recommendations available at the moment.';
    }
    final lines = <String>[];
    for (var i = 0; i < movies.length; i++) {
      final m = movies[i];
      final year = (m.year > 0) ? ' (${m.year})' : '';
      final rating =
          (m.rating > 0) ? ' — ⭐ ${m.rating.toStringAsFixed(1)}/10' : '';
      lines.add('${i + 1}. 🎬 ${m.title}$year$rating');
    }
    return lines.join('\n');
  }

  /// Get similar movies using AI similarity model
  List<Movie> _getSimilarMoviesFromAI(Movie baseMovie, {int limit = 20}) {
    try {
      // Find the index of the base movie
      final movieIndex = _movies.indexWhere((m) => m.id == baseMovie.id);
      if (movieIndex == -1) {
        debugPrint('⚠️ Movie ${baseMovie.title} not found in database');
        return [];
      }

      // Get similarity data for this movie
      final similarityEntry = _similarityData[movieIndex.toString()];
      if (similarityEntry == null) {
        debugPrint(
            '⚠️ No similarity data found for movie at index $movieIndex');
        return [];
      }

      final indices = (similarityEntry['indices'] as List?)?.cast<int>() ?? [];
      final scores = (similarityEntry['scores'] as List?)?.cast<double>() ?? [];

      if (indices.isEmpty || scores.isEmpty) {
        return [];
      }

      final results = <Movie>[];
      for (int i = 0; i < indices.length && results.length < limit; i++) {
        final idx = indices[i];
        if (idx >= 0 && idx < _movies.length) {
          final movie = _movies[idx];
          // Only include movies with valid poster images and non-zero score
          if (movie.posterUrl.isNotEmpty && scores[i] > 0) {
            results.add(movie);
          }
        }
      }

      debugPrint(
          '🧠 AI Similarity: Found ${results.length} matches for ${baseMovie.title}');

      return results;
    } catch (e) {
      debugPrint('❌ Error getting similar movies from AI: $e');
      return [];
    }
  }

  // ----- Helper matching utilities -----
  String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9\s]"), '').trim();
  }

  int _tokenOverlap(String a, String b) {
    final ta =
        _normalize(a).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
    final tb =
        _normalize(b).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
    return ta.intersection(tb).length;
  }

  Movie? _findBaseMovieByName(String name) {
    final target = _normalize(name);
    if (target.isEmpty) return null;

    // 1) Exact match
    try {
      return _movies.firstWhere((m) => _normalize(m.title) == target);
    } catch (_) {}

    // 2) StartsWith / contains
    try {
      return _movies.firstWhere((m) => _normalize(m.title).contains(target));
    } catch (_) {}

    // 3) Token overlap scoring (choose highest overlap)
    int best = 0;
    Movie? bestMovie;
    for (final m in _movies) {
      final score = _tokenOverlap(m.title, name);
      if (score > best) {
        best = score;
        bestMovie = m;
      }
    }

    // require at least one token overlap
    return (best > 0) ? bestMovie : null;
  }

  // Return up to [limit] movies that have posters, sampling randomly for variety
  /// Batch fetch posters from TMDB API for movies with missing posters
  /// Replaces movies that couldn't get posters with alternatives from the pool
  Future<List<Movie>> _enrichMoviesWithPosters(List<Movie> candidates) async {
    // Use effective API key (from secrets.json or compile-time define)
    final apiKey = ApiConfig.effectiveTmdbApiKey;
    if (apiKey.isEmpty) {
      debugPrint('⚠️ TMDB API key not configured, returning movies as-is');
      return candidates;
    }

    final List<Movie> enriched = [];
    final List<Movie> needsPosters = [];
    int postersAdded = 0;

    // Separate movies by poster status
    for (final movie in candidates) {
      if (movie.posterUrl.isNotEmpty) {
        enriched.add(movie);
      } else {
        needsPosters.add(movie);
      }
    }

    // If no movies need posters, return immediately
    if (needsPosters.isEmpty) {
      debugPrint('✅ All ${enriched.length} movies already have posters!');
      return enriched;
    }

    debugPrint(
        '🔄 Fetching posters for ${needsPosters.length} movies from TMDB...');

    // Batch fetch posters from TMDB (with rate limiting)
    for (int i = 0; i < needsPosters.length; i++) {
      final movie = needsPosters[i];

      try {
        // Add delay to avoid rate limiting (100ms between requests)
        if (i > 0) await Future.delayed(const Duration(milliseconds: 100));

        final response = await http
            .get(
              Uri.parse(
                  '${ApiConfig.tmdbBaseUrl}/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(movie.title)}&page=1'),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final results = data['results'] as List?;

          if (results != null && results.isNotEmpty) {
            final posterPath = results[0]['poster_path'];
            if (posterPath != null && posterPath.isNotEmpty) {
              // Update movie with fetched poster
              final enrichedMovie = Movie(
                id: movie.id,
                title: movie.title,
                tags: movie.tags,
                rating: movie.rating,
                year: movie.year,
                runtime: movie.runtime,
                genres: movie.genres,
                posterUrl: 'https://image.tmdb.org/t/p/w342$posterPath',
              );
              enriched.add(enrichedMovie);
              postersAdded++;
              debugPrint('✅ Found poster for: ${movie.title}');
              continue;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error fetching poster for ${movie.title}: $e');
      }

      // If TMDB search failed/no poster found, skip this movie
      // (Don't add it to enriched, we'll replace it)
      debugPrint('⏭️ Skipped (no poster): ${movie.title}');
    }

    debugPrint(
        '✅ Enrichment done: Added $postersAdded posters from TMDB. Total: ${enriched.length}');

    // If we lost movies due to missing posters, fill from original candidates
    if (enriched.length < candidates.length) {
      final lost = candidates.length - enriched.length;
      debugPrint('⚠️ Lost $lost movies (no poster), trying to backfill...');

      // Try to backfill from candidates that have posters
      final backfillPool = candidates
          .where((m) =>
              m.posterUrl.isNotEmpty && !enriched.any((e) => e.id == m.id))
          .toList();

      for (int i = 0; i < lost && i < backfillPool.length; i++) {
        enriched.add(backfillPool[i]);
        debugPrint('📝 Backfilled: ${backfillPool[i].title}');
      }
    }

    return enriched;
  }

  List<Movie> _sampleWithPosters(List<Movie> candidates, int limit) {
    // Separate by poster availability
    final withPosters =
        candidates.where((m) => m.posterUrl.isNotEmpty).toList();
    final withoutPosters =
        candidates.where((m) => m.posterUrl.isEmpty).toList();

    // Shuffle both lists
    final rnd = Random();
    withPosters.shuffle(rnd);
    withoutPosters.shuffle(rnd);

    // Build result: prioritize with posters, include some without (will be enriched)
    final result = <Movie>[];

    // Add all movies with posters first
    result.addAll(withPosters);

    // Add movies without posters (will be enriched from TMDB)
    result.addAll(withoutPosters);

    // Return first 'limit' movies
    // These will be enriched with TMDB posters if missing
    return result.take(limit).toList();
  }

  // suggestions text removed per user request

  // ----- Helper methods for raw input handling -----
  String _handleGenreRecommendation(String genre, String originalMessage,
      {bool isArabic = false}) {
    final extractedGenre = IntentDetector.extractGenre(genre, _genreMap);

    if (extractedGenre == null) {
      return isArabic
          ? 'أي نوع تفضل؟ مثلا: أكشن، رعب، خيال علمي...'
          : 'Which genre do you prefer? e.g. action, horror, sci-fi...';
    }

    // Get all movies for this genre + related genres
    var recs = <Movie>[];

    // Primary: Genre matching with related keywords
    final genreResults =
        RecommendationEngine.recommendByGenre(_movies, extractedGenre);
    for (final m in genreResults) {
      if (!recs.any((c) => c.id == m.id)) {
        recs.add(m);
      }
    }

    // Secondary: Token-based search
    if (recs.length < 100) {
      final tokenRecs =
          RecommendationEngine.recommendForQuery(_movies, extractedGenre);
      for (final m in tokenRecs) {
        if (!recs.any((c) => c.id == m.id)) {
          recs.add(m);
          if (recs.length >= 200) break; // Collect enough
        }
      }
    }

    // Tertiary: Similarity-based search using genre keywords
    if (recs.length < 100) {
      final relatedKeywords = [
        'action',
        'adventure',
        'drama',
        'horror',
        'comedy',
        'romance',
        'thriller',
        'crime',
        'fantasy',
        'animation',
        'family',
        'documentary',
        'historical',
        'war',
        'western',
        'sports'
      ];

      for (final keyword in relatedKeywords) {
        final similarRecs =
            RecommendationEngine.recommendForQuery(_movies, keyword);
        for (final m in similarRecs) {
          if (!recs.any((c) => c.id == m.id)) {
            recs.add(m);
            if (recs.length >= 300) break;
          }
        }
        if (recs.length >= 300) break;
      }
    }

    // Filter for movies with posters and sample 50
    final results = _sampleWithPosters(recs, 50);

    if (results.isEmpty) {
      return isArabic
          ? 'آسف، لم أتمكن من العثور على أفلام من هذا النوع. جرب نوعاً آخر.'
          : 'Sorry, I could not find movies of this genre. Try another one.';
    }

    if (results.length < 50 && kDebugMode) {
      // Only log in debug mode
      debugPrint(
          '⚠️ Warning: Only ${results.length} movies found for genre: $extractedGenre');
    }

    _lastRecommendations = results;
    return _formatMovies(_lastRecommendations, isArabic: isArabic);
  }

  String _handleSimilarMovie(String message, {bool isArabic = false}) {
    // Remove common extra words before searching
    final name = message
        .replaceAll(RegExp(r"\blike\b", caseSensitive: false), '')
        .replaceAll(RegExp(r"\bsimilar\b", caseSensitive: false), '')
        .replaceAll(RegExp(r"\bto\b", caseSensitive: false), '')
        .replaceAll(RegExp(r"\bمثل\b", caseSensitive: false), '')
        .replaceAll(RegExp(r"\bتشابه\b", caseSensitive: false), '')
        .replaceAll(RegExp(r"\bشبيه\b", caseSensitive: false), '')
        .replaceAll(RegExp(r"\bمشابه\b", caseSensitive: false), '')
        .trim();

    if (name.isEmpty) {
      return isArabic
          ? 'أي فيلم تريد البحث عن أفلام مشابهة له؟'
          : 'Which movie would you like to find similar movies to?';
    }

    // Find the base movie using a robust strategy (exact, contains, token overlap)
    Movie? baseMovie = _findBaseMovieByName(name);

    List<Movie> recs = [];

    // Use AI-based recommendations first if possible
    if (baseMovie != null) {
      final similarMovies = _getSimilarMoviesFromAI(baseMovie, limit: 19);
      recs.addAll(similarMovies);
      debugPrint(
          '🧠 AI model: ${recs.length} recommendations for ${baseMovie.title}');
    }

    // Fallback 1: Use tags from the base movie (not the movie name!)
    // This ensures we get movies with similar content, not movies with similar names
    if (recs.length < 50 && baseMovie != null) {
      final movieTags = baseMovie.tags; // Use the actual movie's tags
      if (movieTags.isNotEmpty) {
        final tagBasedRecs =
            RecommendationEngine.recommendForQuery(_movies, movieTags);
        for (final m in tagBasedRecs) {
          if (!recs.any((c) => c.id == m.id) && m.id != baseMovie.id) {
            recs.add(m);
          }
        }
        debugPrint(
            '📌 Tag-based fallback for "${baseMovie.title}": ${tagBasedRecs.length} found');
      }
    }

    // Fallback 2: Search by genre if we still don't have enough
    if (recs.length < 50 && baseMovie != null) {
      final genres = baseMovie.genres;
      if (genres.isNotEmpty) {
        // Search using the first genre
        final genreRecs =
            RecommendationEngine.recommendForQuery(_movies, genres.first);
        for (final m in genreRecs) {
          if (!recs.any((c) => c.id == m.id) && m.id != baseMovie.id) {
            recs.add(m);
            if (recs.length >= 100) break;
          }
        }
        debugPrint(
            '🎬 Genre-based fallback (${genres.first}): ${genreRecs.length} found');
      }
    }

    // Fallback 3: If base movie not found, try name-based query as last resort
    if (recs.isEmpty) {
      final fallback = RecommendationEngine.recommendForQuery(_movies, name);
      for (final m in fallback) {
        if (!recs.any((c) => c.id == m.id)) {
          recs.add(m);
        }
      }
      debugPrint(
          '⚠️ No base movie found, using name-based fallback: ${fallback.length} found');
    }

    // Deduplicate while preserving order
    final seen = <int>{};
    final deduped = <Movie>[];
    for (final m in recs) {
      if (seen.contains(m.id)) continue;
      seen.add(m.id);
      deduped.add(m);
    }

    // Exclude movies without valid poster images (AFTER collecting enough)
    final withPosters = deduped.where((m) => m.posterUrl.isNotEmpty).toList();

    // Ensure base movie is visible (insert at front) if found and has poster
    if (baseMovie != null && baseMovie.posterUrl.isNotEmpty) {
      withPosters.removeWhere((m) => m.id == baseMovie.id);
      withPosters.insert(0, baseMovie);
    }

    final results = _sampleWithPosters(withPosters, 50);
    _lastRecommendations = results;

    if (results.isEmpty) {
      return isArabic
          ? 'لم أتمكن من العثور على أفلام مشابهة لـ "$name". جرب عنوان آخر أو اطلب نوع معين.'
          : 'I could not find similar movies to "$name". Try another title or ask for a specific genre.';
    }

    return _formatMovies(results, isArabic: isArabic);
  }
}
