import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:movies/home_screen.dart';
import 'package:movies/screens/forget_password.dart';
import 'package:movies/screens/login_screen.dart';
import 'package:movies/screens/profile.dart';
import 'package:movies/screens/update_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movies/onboarding_screen.dart';
import 'package:movies/splash_screen.dart';
import 'package:movies/screens/register.dart';
import 'package:movies/auth_wrapper.dart';
import 'package:movies/services/theme_service.dart';
import 'package:movies/services/localization_service.dart';
import 'package:movies/movie_details_screen.dart';
import 'package:movies/models/movie.dart';
import 'package:movies/firebase_options.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:movies/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Theme Service
  await ThemeService().init();

  // Initialize Localization Service (load saved language)
  await LocalizationService().init();

  // Shared Preferences to determine whether Onboarding has been shown
  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  // Try loading runtime secrets (assets/secrets.json) as a fallback
  try {
    final raw = await rootBundle.loadString('assets/secrets.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    if (map.containsKey('TMDB_API_KEY')) {
      ApiConfig.tmdbApiKeyRuntime = map['TMDB_API_KEY'] as String? ?? '';
    }
  } catch (e) {
    // No secrets file provided; continue.
  }

  runApp(MyApp(showHome: showHome));
}

// Test function to check Firebase connection
Future<void> testFirebaseConnection() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    // Firebase connection check
    if (user != null) {
      // User is signed in
    }
  } catch (e) {
    // Firebase connection failed
  }
}

class MyApp extends StatefulWidget {
  final bool showHome;

  const MyApp({super.key, required this.showHome});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeService = ThemeService();
  final _localizationService = LocalizationService();

  @override
  void initState() {
    super.initState();
    // Listen to theme and locale changes
    _themeService.themeNotifier.addListener(_updateTheme);
    _localizationService.localeNotifier.addListener(_updateLocale);
  }

  void _updateTheme() {
    setState(() {});
  }

  void _updateLocale() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeService.themeNotifier.removeListener(_updateTheme);
    _localizationService.localeNotifier.removeListener(_updateLocale);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie App',
      theme: _themeService.getTheme(),
      locale: _localizationService.currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      initialRoute: SplashScreen.routeName,
      routes: {
        AuthWrapper.routeName: (context) => AuthWrapper(),
        MainScreen.routeName: (context) => MainScreen(),
        OnboardingScreen.routeName: (context) => OnboardingScreen(),
        SplashScreen.routeName: (context) => SplashScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
        RegisterScreen.routeName: (context) => RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) => ForgotPasswordScreen(),
        ProfileScreen.routeName: (context) => ProfileScreen(),
        UpdateProfileScreen.routeName: (context) => UpdateProfileScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle named route for movie details with Movie argument
        if (settings.name == '/movie_details') {
          final args = settings.arguments;
          if (args is Movie) {
            return MaterialPageRoute(
              builder: (context) => MovieDetailsScreen(movie: args),
              settings: settings,
            );
          }
        }
        // Unknown route
        return null;
      },
    );
  }
}
