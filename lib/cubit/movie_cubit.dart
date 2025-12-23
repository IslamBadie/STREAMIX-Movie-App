import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:movies/cubit/states.dart';
import 'package:movies/models/movie.dart';
import 'package:movies/services/http_service.dart';
import 'package:movies/services/error_handler.dart';
import 'package:movies/services/translation_service.dart';
import 'package:movies/config/api_config.dart';
import 'package:movies/services/localization_service.dart';

class MovieCubit extends Cubit<MovieState> {
  MovieCubit() : super(MovieInitial());

  final HttpService _httpService = HttpService();
  final TranslationService _translationService = TranslationService();

  Future<void> fetchMovieDetails(int movieId) async {
    try {
      emit(MovieLoading());

      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(MovieError('TMDB API key not configured'));
        return;
      }

      // Always fetch English version for complete data
      final enResponse = await _httpService.get(
        '${ApiConfig.tmdbBaseUrl}/movie/$movieId?api_key=$apiKey&append_to_response=videos,images,credits,translations&region=US',
      );

      if (enResponse.statusCode != 200) {
        emit(MovieError('Failed to fetch movie details'));
        return;
      }

      final enData = HttpService.parseJsonResponse(enResponse.body);
      Movie movie = Movie.fromTmdbDetails(enData);

      // If Arabic is selected, check for translations in the response
      if (LocalizationService().isArabic) {
        try {
          // Check translations from the append_to_response data
          final translations = enData['translations']?['translations'] as List?;
          String? arOverview;

          if (translations != null && translations.isNotEmpty) {
            for (var translation in translations) {
              if ((translation['iso_639_1'] == 'ar' ||
                      translation['iso_639_1'] == 'ar-SA' ||
                      translation['english_name']
                              ?.toString()
                              .toLowerCase()
                              .contains('arabic') ==
                          true) &&
                  translation['data']?['overview']?.isNotEmpty == true) {
                arOverview = translation['data']['overview'];
                break;
              }
            }
          }

          // If no translation found in response, fetch separately
          if (arOverview == null || arOverview.isEmpty) {
            final arResponse = await _httpService.get(
              '${ApiConfig.tmdbBaseUrl}/movie/$movieId?api_key=$apiKey&language=ar&region=SA',
            );

            if (arResponse.statusCode == 200) {
              final arData = HttpService.parseJsonResponse(arResponse.body);
              arOverview = arData['overview'] as String? ?? '';
            }
          }

          // Use Arabic overview if it's valid and different from English
          if (arOverview != null &&
              arOverview.isNotEmpty &&
              arOverview.length > 10 &&
              arOverview != (enData['overview'] ?? '')) {
            movie = movie.copyWith(
              summary: arOverview,
              descriptionFull: arOverview,
              synopsis: arOverview,
            );
          } else if ((arOverview?.isEmpty ?? true) &&
              (enData['overview'] as String? ?? '').isNotEmpty) {
            // No Arabic translation found, use Google Translate for English overview
            try {
              final englishOverview = enData['overview'] as String? ?? '';
              if (englishOverview.length > 10) {
                final translatedOverview = await _translationService
                    .translateToArabic(englishOverview);
                if (translatedOverview.isNotEmpty &&
                    translatedOverview != englishOverview) {
                  movie = movie.copyWith(
                    summary: translatedOverview,
                    descriptionFull: translatedOverview,
                    synopsis: translatedOverview,
                  );
                }
              }
            } catch (_) {
              // Translation failed, keep English as fallback
            }
          }
        } catch (_) {
          // Failed to fetch Arabic, use English as fallback
        }
      }

      // Emit the loaded movie so UI can render details while similar movies load
      emit(MovieLoaded(movie));
      await fetchSimilarMovies(movieId, movie);
    } catch (e) {
      final errorMessage = ErrorHandler.getGeneralErrorMessage(e);
      emit(MovieError(errorMessage));
      ErrorHandler.logError('MovieCubit', e);
    }
  }

  Future<void> fetchSimilarMovies(int movieId, Movie currentMovie) async {
    try {
      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        emit(MovieLoaded(currentMovie));
        return;
      }

      final languageParam = LocalizationService().isArabic ? 'ar' : 'en';
      final resp = await _httpService.get(
        '${ApiConfig.tmdbBaseUrl}/movie/$movieId/similar?api_key=$apiKey&language=$languageParam&page=1',
      );

      if (resp.statusCode == 200) {
        final data = HttpService.parseJsonResponse(resp.body);
        final results = data['results'] as List?;
        final movies = results
                ?.map((m) => Movie.fromTmdbList(m as Map<String, dynamic>))
                .where((m) => m.id != movieId)
                .toList() ??
            [];
        emit(MovieLoaded(currentMovie, similarMovies: movies));
      } else {
        emit(MovieLoaded(currentMovie));
      }
    } catch (e) {
      emit(MovieLoaded(currentMovie));
    }
  }
}
