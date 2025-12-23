/// API Configuration file
/// All sensitive API keys should be stored in environment variables
/// Never commit these keys to version control!
library;

class ApiConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hnihhqdlcozfqolxwddw.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuaWhocWRsY296ZnFvbHh3ZGR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2MTk1MzAsImV4cCI6MjA0ODE5NTUzMH0.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuaWhocWRsY296ZnFvbmd4ZGR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2MTk1MzAsImV4cCI6MjA0ODE5NTUzMH0',
  );

  // Movie API Configuration
  static const String movieApiBaseUrl = 'https://yts.lt/api/v2';
  static const int movieApiTimeout = 15; // seconds
  static const int maxRetries = 3;

  // Firebase Configuration
  static const String firebaseProjectId = 'traintracker-56f07';

  // App Configuration
  static const int moviePageLimit = 50;
  static const int searchDebounceMs = 500;
  static const int imageCacheDurationDays = 30;

  // TMDB API Key
  // Provide this at build/run time using --dart-define=TMDB_API_KEY=<your_key>
  // Example:
  // flutter run --dart-define=TMDB_API_KEY=6b597b6ab89f3d87f18ad7e84262d158
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );

  // Runtime override for TMDB API key. This can be set at app startup
  // by reading an untracked `assets/secrets.json` file when
  // `--dart-define` is not used. Keep empty by default.
  static String tmdbApiKeyRuntime = '';

  /// Returns the effective TMDB API key. Prefers the compile-time
  /// `--dart-define` value but falls back to the runtime override.
  static String get effectiveTmdbApiKey =>
      tmdbApiKey.isNotEmpty ? tmdbApiKey : tmdbApiKeyRuntime;

  // TMDB base URL
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  // Basic mapping from genre name (used in UI) to TMDB genre IDs
  // This is a best-effort map for common genres used in the app.
  static const Map<String, int> tmdbGenreIds = {
    'Action': 28,
    'Adventure': 12,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Family': 10751,
    'Fantasy': 14,
    'History': 36,
    'Horror': 27,
    'Music': 10402,
    'Mystery': 9648,
    'Romance': 10749,
    'Sci-Fi': 878,
    'Science Fiction': 878,
    'Sport': 10752,
    'Thriller': 53,
    'War': 10752,
    'Western': 37,
  };
}
