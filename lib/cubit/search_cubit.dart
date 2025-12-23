import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import 'package:movies/cubit/states.dart';
import 'package:movies/models/movie.dart';
import 'package:movies/services/http_service.dart';
import 'package:movies/config/api_config.dart';
import 'package:movies/services/localization_service.dart';

/// Search Cubit with debounce to prevent excessive API calls
class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  Timer? _debounceTimer;
  final HttpService _httpService = HttpService();
  String _currentQuery = '';
  int _currentPage = 1;
  List<Movie> _allResults = [];
  bool _isFetching = false;

  /// Search movies with debounce
  void searchMovies(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Debounce the search
    _debounceTimer = Timer(
      Duration(milliseconds: ApiConfig.searchDebounceMs),
      () async {
        _currentQuery = query;
        _currentPage = 1;
        _allResults = [];
        await _performSearchAndFetchMore(query);
      },
    );
  }

  /// Perform the actual search
  Future<void> _performSearch(String query, {int page = 1}) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      if (page == 1) emit(SearchLoading());

      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(SearchError('TMDB API key not configured'));
        return;
      }

      final languageParam =
          LocalizationService().isArabic ? '&language=ar' : '';
      final response = await _httpService.get(
        '${ApiConfig.tmdbBaseUrl}/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(query)}&page=$page$languageParam',
      );

      if (response.statusCode == 200) {
        final data = HttpService.parseJsonResponse(response.body);
        final results = data['results'] as List?;
        final movies = results
                ?.map((movie) =>
                    Movie.fromTmdbList(movie as Map<String, dynamic>))
                .toList() ??
            [];

        if (page == 1) {
          _allResults = movies;
        } else {
          _allResults.addAll(movies);
        }

        emit(SearchLoaded(_allResults));
      } else {
        emit(SearchError('Failed to search movies'));
      }
    } catch (e) {
      emit(SearchError('An error occurred while searching: $e'));
    } finally {
      _isFetching = false;
    }
  }

  /// Fetch additional pages until we have at least 50 results
  Future<void> _performSearchAndFetchMore(String query) async {
    int page = 1;
    _allResults = [];

    try {
      emit(SearchLoading());

      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(SearchError('TMDB API key not configured'));
        return;
      }

      final languageParam =
          LocalizationService().isArabic ? '&language=ar' : '';

      // Fetch pages until we have at least moviePageLimit results or reach a reasonable limit
      while (_allResults.length < ApiConfig.moviePageLimit && page <= 3) {
        final response = await _httpService.get(
          '${ApiConfig.tmdbBaseUrl}/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(query)}&page=$page$languageParam',
        );

        if (response.statusCode == 200) {
          final data = HttpService.parseJsonResponse(response.body);
          final results = data['results'] as List?;
          final movies = results
                  ?.map((movie) =>
                      Movie.fromTmdbList(movie as Map<String, dynamic>))
                  .toList() ??
              [];

          if (movies.isEmpty) break; // No more results

          _allResults.addAll(movies);
          page++;
        } else {
          break;
        }
      }

      // Limit to exactly moviePageLimit results
      if (_allResults.length > ApiConfig.moviePageLimit) {
        _allResults = _allResults.take(ApiConfig.moviePageLimit).toList();
      }

      emit(SearchLoaded(_allResults));
    } catch (e) {
      emit(SearchError('An error occurred while searching: $e'));
    }
  }

  /// Load next page of current search
  Future<void> loadMore() async {
    if (_currentQuery.isEmpty) return;
    if (_isFetching) return;
    _currentPage++;
    await _performSearch(_currentQuery, page: _currentPage);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
