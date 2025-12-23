import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movies/screens/forget_password.dart';
import 'package:movies/screens/register.dart';
import 'package:movies/home_screen.dart';
import 'package:movies/services/localization_service.dart';
import 'package:movies/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define constants for colors and styles
const kBackgroundColor = Color(0xFF1A1A1A);
const kTextFieldColor = Color(0xFF2C2C2C);
const kButtonColor = Color(0xFFF6BD00); // Changed to blue
var kHintTextStyle = TextStyle(color: Colors.grey[600]);
final kBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide.none,
);

class LoginScreen extends StatefulWidget {
  static const String routeName = "login";

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late LocalizationService _localizationService;
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _localizationService = LocalizationService();
    _themeService = ThemeService();
    _loadPreferences();
    // Listen to locale changes
    _localizationService.localeNotifier.addListener(() {
      setState(() {});
    });
    // Listen to theme changes
    _themeService.themeNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Use correct keys that match LocalizationService and ThemeService
    final lang = prefs.getString('app_locale') ?? 'en';
    final isDark = prefs.getBool('isDarkMode') ?? true;
    LocalizationService().setLocale(Locale(lang));
    ThemeService().setDarkMode(isDark);
  }

  Future<void> _setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', languageCode);
    LocalizationService().setLocale(Locale(languageCode));
    setState(() {});
  }

  Future<void> _setTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    ThemeService().setDarkMode(isDark);
    setState(() {});
  }

  // Sign-in function using Firebase
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if email is verified
      if (userCredential.user != null) {
        // Reload user to get latest email verification status
        await userCredential.user!.reload();

        if (!userCredential.user!.emailVerified) {
          if (mounted) {
            // Email not verified - show dialog with resend option
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  LocalizationService().t('email_not_verified'),
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );

            // Show dialog with option to resend verification email
            if (mounted) {
              _showEmailVerificationDialog(userCredential.user!);
            }
          }

          // Sign out the user since email is not verified
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }

        // Email is verified, proceed with login
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            final prefs = await SharedPreferences.getInstance();
            final userData = userDoc.data();

            if (userData != null) {
              await prefs.setString('user_name', userData['name'] ?? '');
              await prefs.setString('user_email', userData['email'] ?? '');
              await prefs.setString('user_phone', userData['phone'] ?? '');
              await prefs.setString('user_avatar', 'assets/images/avatar.png');
              await prefs.setString(
                  'gender', userData['gender'] ?? 'not_selected');
              await prefs.setString('about_me', userData['about_me'] ?? '');

              if (userData['date_of_birth'] != null) {
                await prefs.setString(
                    'date_of_birth', userData['date_of_birth'].toString());
              }

              // Fetch user lists from Firestore (optional)
              try {
                final watchlist =
                    List<String>.from(userData['watchlist'] ?? []);
                final history = List<String>.from(userData['history'] ?? []);
                final favorites =
                    List<String>.from(userData['favorites'] ?? []);

                // Save lists to SharedPreferences
                await prefs.setStringList('watchlist', watchlist);
                await prefs.setStringList('history', history);
                await prefs.setStringList('favorites', favorites);

                debugPrint('User lists loaded from Firebase');
              } catch (e) {
                debugPrint('Firebase list sync optional: $e');
              }
            }
          }
        } catch (firestoreError) {
          debugPrint(
              'Error fetching user data from Firestore: $firestoreError');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().t('login_successful')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = LocalizationService().t('error_occurred');

      if (e.code == 'user-not-found') {
        errorMessage = LocalizationService().t('user_not_found');
      } else if (e.code == 'wrong-password') {
        errorMessage = LocalizationService().t('incorrect_password');
      } else if (e.code == 'invalid-email') {
        errorMessage = LocalizationService().t('invalid_email');
      } else if (e.code == 'user-disabled') {
        errorMessage = LocalizationService().t('user_disabled');
      } else if (e.code == 'too-many-requests') {
        errorMessage = LocalizationService().t('too_many_attempts');
      } else if (e.code == 'network-request-failed') {
        errorMessage = LocalizationService().t('network_error');
      } else if (e.message?.contains('reCAPTCHA') == true ||
          e.message?.contains('www.googleapis.com') == true) {
        errorMessage = LocalizationService().t('security_verification_issue');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().t('error')}: $e',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show dialog to resend verification email
  void _showEmailVerificationDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService().t('email_verification_required')),
        content: Text(
          LocalizationService().t('please_verify_email_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService().t('dismiss')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _resendVerificationEmail(user);
            },
            child: Text(LocalizationService().t('resend_verification_email')),
          ),
        ],
      ),
    );
  }

  // Resend verification email
  Future<void> _resendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().t('verification_email_resent'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().t('error')}: $e',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Language and Theme buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setLanguage('en'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: LocalizationService()
                                            .currentLocale
                                            .languageCode ==
                                        'en'
                                    ? Colors.yellow
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Center(
                                child: Text('🇺🇸',
                                    style: TextStyle(fontSize: 20))),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _setLanguage('ar'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: LocalizationService()
                                            .currentLocale
                                            .languageCode ==
                                        'ar'
                                    ? Colors.yellow
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Center(
                                child: Text('🇪🇬',
                                    style: TextStyle(fontSize: 20))),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        ThemeService().isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () => _setTheme(!ThemeService().isDarkMode),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Image.asset('assets/images/rectangle.png',
                    width: 100, height: 100),
                SizedBox(height: 60),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    hintText: LocalizationService().t('email'),
                    hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.labelSmall?.color),
                    prefixIcon: Icon(Icons.email,
                        color: Theme.of(context).textTheme.labelSmall?.color),
                    border: kBorder,
                    focusedBorder: kBorder,
                    enabledBorder: kBorder,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? LocalizationService().t('enter_your_email')
                      : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    hintText: LocalizationService().t('password'),
                    hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.labelSmall?.color),
                    prefixIcon: Icon(Icons.lock,
                        color: Theme.of(context).textTheme.labelSmall?.color),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(context).textTheme.labelSmall?.color),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: kBorder,
                    focusedBorder: kBorder,
                    enabledBorder: kBorder,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) =>
                      (value?.isEmpty ?? true) || (value?.length ?? 0) < 6
                          ? LocalizationService().t('password_min_length')
                          : null,
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                          context, ForgotPasswordScreen.routeName);
                    },
                    child: Text(LocalizationService().t('forgotPassword'),
                        style: TextStyle(color: kButtonColor)),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.black)
                        : Text(LocalizationService().t('sign_in'),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[700])),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(LocalizationService().t('or'),
                          style: kHintTextStyle)),
                  Expanded(child: Divider(color: Colors.grey[700])),
                ]),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Google sign-in is currently unavailable'),
                                  backgroundColor: Colors.grey),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Text('G',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    label: Text(LocalizationService().t('sign_in_with_google'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(LocalizationService().t('dont_have_account'),
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 16)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, RegisterScreen.routeName),
                      child: Text(LocalizationService().t('create_account'),
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
