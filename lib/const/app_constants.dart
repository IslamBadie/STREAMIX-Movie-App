/// App Constants - Safe to commit to version control
/// Sensitive keys are stored in lib/config/api_config.dart
library;

class AppConstants {
  // Pagination
  static const int itemsPerPage = 20;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // Cache
  static const int imageCacheDaysExpiry = 30;
  static const int movieDataCacheDaysExpiry = 7;

  // Movie API - Deprecated: Now using TMDB via lib/config/api_config.dart
  // All movie API calls have been migrated to TMDB endpoints
  // Use ApiConfig.tmdbBaseUrl and ApiConfig.tmdbApiKey instead

  // Route names
  static const String homeRoute = 'home';
  static const String loginRoute = 'login';
  static const String registerRoute = 'register';
  static const String splashRoute = 'splash';
  static const String profileRoute = 'profile';
}
