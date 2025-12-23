import 'package:flutter_bloc/flutter_bloc.dart';
// imports

import 'package:movies/cubit/states.dart';
import 'package:movies/services/localization_service.dart';
import 'package:movies/models/movie.dart';
import 'package:movies/services/http_service.dart';
import 'package:movies/services/error_handler.dart';
import 'package:movies/config/api_config.dart';

/// Browse Cubit with pagination support
class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit() : super(BrowseInitial());

  final HttpService _httpService = HttpService();
  int _currentPage = 1;
  String _currentCategory = 'Action';
  List<Movie> _allMovies = [];

  /// Fetch movies by category with pagination
  Future<void> fetchMovies(String category, {bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        _currentPage = 1;
        _allMovies = [];
        emit(BrowseLoading());
      }

      _currentCategory = category;

      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(BrowseError('TMDB API key not configured'));
        return;
      }

      // Try to map genre name to TMDB genre id; if not found use discover without genre
      final genreId = ApiConfig.tmdbGenreIds[category];
      final languageParam =
          LocalizationService().isArabic ? '&language=ar' : '';
      final url = genreId != null
          ? '${ApiConfig.tmdbBaseUrl}/discover/movie?api_key=$apiKey&with_genres=$genreId&page=$_currentPage$languageParam'
          : '${ApiConfig.tmdbBaseUrl}/discover/movie?api_key=$apiKey&page=$_currentPage$languageParam';

      final response = await _httpService.get(url);

      if (response.statusCode == 200) {
        final data = HttpService.parseJsonResponse(response.body);
        final results = data['results'] as List?;

        var movies = results
                ?.map((movie) =>
                    Movie.fromTmdbList(movie as Map<String, dynamic>))
                .toList() ??
            [];

        // Ensure exactly moviePageLimit per category (20)
        if (movies.length > ApiConfig.moviePageLimit) {
          movies = movies.take(ApiConfig.moviePageLimit).toList();
        }

        // Remove duplicates by ID
        final Map<int, Movie> movieMap = {};
        for (var movie in movies) {
          movieMap[movie.id] = movie;
        }
        movies = movieMap.values.toList();

        // Sort by newest first using year
        movies.sort((a, b) => b.year.compareTo(a.year));

        if (isLoadMore) {
          _allMovies.addAll(movies);
        } else {
          _allMovies = movies;
        }

        emit(BrowseLoaded(_allMovies, category));
      } else {
        emit(BrowseError('Failed to fetch movies'));
      }
    } catch (e) {
      final errorMessage = ErrorHandler.getGeneralErrorMessage(e);
      emit(BrowseError(errorMessage));
      ErrorHandler.logError('BrowseCubit', e);
    }
  }

  /// Load more movies for pagination
  Future<void> loadMoreMovies() async {
    _currentPage++;
    await fetchMovies(_currentCategory, isLoadMore: true);
  }

  /// Fetch top 10 rated movies
  Future<void> fetchTopRatedMovies() async {
    try {
      emit(BrowseLoading());
      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(BrowseError('TMDB API key not configured'));
        return;
      }

      final languageParam =
          LocalizationService().isArabic ? '&language=ar' : '';
      final response = await _httpService.get(
          '${ApiConfig.tmdbBaseUrl}/movie/top_rated?api_key=$apiKey&page=1$languageParam');
      if (response.statusCode == 200) {
        final data = HttpService.parseJsonResponse(response.body);
        final results = data['results'] as List?;
        var movies = results
                ?.map((movie) =>
                    Movie.fromTmdbList(movie as Map<String, dynamic>))
                .toList() ??
            [];

        // Take top 20 by rating but limit to configured page size
        movies.sort((a, b) => b.rating.compareTo(a.rating));
        final top = movies.take(ApiConfig.moviePageLimit).toList();
        emit(BrowseLoaded(top, 'Top Rated'));
      } else {
        emit(BrowseError('Failed to fetch top rated movies'));
      }
    } catch (e) {
      final errorMessage = ErrorHandler.getGeneralErrorMessage(e);
      emit(BrowseError(errorMessage));
      ErrorHandler.logError('BrowseCubit', e);
    }
  }

  /// Change category and reset pagination
  void changeCategory(String category) {
    fetchMovies(category);
  }

  /// Fetch popular/trending movies (for carousel / Available Now)
  Future<void> fetchTrendingMovies() async {
    try {
      emit(BrowseLoading());
      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(BrowseError('TMDB API key not configured'));
        return;
      }

      final languageParam =
          LocalizationService().isArabic ? '&language=ar' : '';
      final response = await _httpService.get(
          '${ApiConfig.tmdbBaseUrl}/movie/popular?api_key=$apiKey&page=1$languageParam');

      if (response.statusCode == 200) {
        final data = HttpService.parseJsonResponse(response.body);
        final results = data['results'] as List?;
        var movies = results
                ?.map((movie) =>
                    Movie.fromTmdbList(movie as Map<String, dynamic>))
                .toList() ??
            [];

        // Limit to configured page size
        if (movies.length > ApiConfig.moviePageLimit) {
          movies = movies.take(ApiConfig.moviePageLimit).toList();
        }

        // sort by popularity
        movies.sort((a, b) => (b.likeCount ?? 0).compareTo(a.likeCount ?? 0));
        emit(BrowseLoaded(movies, 'Trending'));
      } else {
        emit(BrowseError('Failed to fetch trending movies'));
      }
    } catch (e) {
      final errorMessage = ErrorHandler.getGeneralErrorMessage(e);
      emit(BrowseError(errorMessage));
      ErrorHandler.logError('BrowseCubit', e);
    }
  }

  /// Reset to first page
  void reset() {
    _currentPage = 1;
    _allMovies = [];
    emit(BrowseInitial());
  }
}
