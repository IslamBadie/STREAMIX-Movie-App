import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movies/services/localization_service.dart';

// Define constants for colors and styles to improve maintainability
const kBackgroundColor = Color(0xFF2C2C2C);
const kTextFieldColor = Color(0xFF3C3C3C);
const kButtonColor = Color(0xFFFFC107);
const kHintTextStyle = TextStyle(color: Colors.white54);
final kBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide.none,
);
final kFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: Colors.orange, width: 2),
);
final kErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: Colors.red, width: 1),
);
final kFocusedErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: Colors.red, width: 2),
);

class RegisterScreen extends StatefulWidget {
  static const String routeName = "register";

  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final obscurePasswordNotifier = ValueNotifier<bool>(true);
  final obscureConfirmPasswordNotifier = ValueNotifier<bool>(true);

  int _selectedAvatar = 1;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    LocalizationService().localeNotifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService().t('passwords_not_match')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Register the user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Save user data to Firestore (best-effort)
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'gender': 'not_selected',
            'about_me': '',
            'avatar_index': _selectedAvatar,
            'created_at': DateTime.now().toIso8601String(),
            'watchlist': [],
            'history': [],
            'favorites': [],
          });
        } catch (firestoreError) {
          debugPrint('Error saving data to Firestore: $firestoreError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService().t('failed_save_server')),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }

        // Persist basic profile fields locally so Profile and Edit Profile show them immediately
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', _nameController.text.trim());
          await prefs.setString('user_phone', _phoneController.text.trim());
          await prefs.setString('user_email', _emailController.text.trim());
          // Use default avatar asset path for now
          await prefs.setString('user_avatar', 'assets/images/avatar.png');
          // Set gender to not_selected by default
          await prefs.setString('gender', 'not_selected');
          // Initialize empty lists
          await prefs.setStringList('watchlist', []);
          await prefs.setStringList('history', []);
          await prefs.setStringList('favorites', []);
        } catch (prefsError) {
          debugPrint('Failed to write SharedPreferences: $prefsError');
        }

        // Send email verification
        try {
          if (!user.emailVerified) {
            await user.sendEmailVerification();

            if (mounted) {
              // Show email verification message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    LocalizationService().t('email_verification_link_sent'),
                  ),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 4),
                ),
              );

              // Wait briefly before navigation
              await Future.delayed(Duration(seconds: 4));

              // Navigate to the login page
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocalizationService()
                          .t('please_verify_email_before_login'),
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );

                await Future.delayed(Duration(seconds: 2));

                if (mounted) {
                  Navigator.pushReplacementNamed(context, 'login');
                }
              }
            }
          }
        } catch (emailError) {
          debugPrint('Error sending verification email: $emailError');

          if (mounted) {
            // Even if email verification fails, allow user to proceed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  LocalizationService()
                      .t('registration_successful_but_email_issue'),
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );

            await Future.delayed(Duration(seconds: 3));

            if (mounted) {
              Navigator.pushReplacementNamed(context, 'login');
            }
          }
        }

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().t('registration_successful')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Wait briefly to ensure the message is visible before navigation
          await Future.delayed(Duration(seconds: 3));

          // Navigate to the login page
          if (mounted) {
            Navigator.pushReplacementNamed(context, 'login');
          }
        }
      }
    } on FirebaseAuthException catch (error) {
      String errorMessage = LocalizationService().t('error_occurred');
      if (error.code == 'email-already-in-use') {
        errorMessage = LocalizationService().t('email_already_in_use');
      } else if (error.code == 'weak-password') {
        errorMessage = LocalizationService().t('weak_password');
      } else if (error.code == 'invalid-email') {
        errorMessage = LocalizationService().t('invalid_email');
      } else if (error.code == 'network-request-failed') {
        errorMessage = LocalizationService().t('network_error');
      } else if (error.message?.contains('reCAPTCHA') == true ||
          error.message?.contains('www.googleapis.com') == true) {
        errorMessage = LocalizationService().t('security_verification_issue');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      // Log the unexpected error for debugging
      debugPrint('Unexpected error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().t('error')}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).iconTheme.color),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      LocalizationService().t('register'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAvatarOption(0, '👨‍💼', Colors.green),
                          _buildAvatarOption(1, '👨', Colors.red),
                          _buildAvatarOption(2, '👨‍🦰', Colors.orange),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        LocalizationService().t('pick_avatar'),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.labelSmall?.color,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 40),
                      _buildTextField(
                        controller: _nameController,
                        hintText: LocalizationService().t('name'),
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocalizationService()
                                .t('please_enter_your_name');
                          }
                          if (value.length < 2) {
                            return '${LocalizationService().t('name')} must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        hintText: LocalizationService().t('email'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocalizationService()
                                .t('please_enter_your_email');
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return LocalizationService().t('invalid_email');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ValueListenableBuilder<bool>(
                        valueListenable: obscurePasswordNotifier,
                        builder: (context, obscurePassword, child) {
                          return _buildTextField(
                            controller: _passwordController,
                            hintText: LocalizationService().t('password'),
                            icon: Icons.lock_outline,
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onPressed: () {
                                obscurePasswordNotifier.value =
                                    !obscurePassword;
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return LocalizationService()
                                    .t('please_enter_password');
                              }
                              if (value.length < 6) {
                                return LocalizationService()
                                    .t('password_min_length');
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      ValueListenableBuilder<bool>(
                        valueListenable: obscureConfirmPasswordNotifier,
                        builder: (context, obscureConfirmPassword, child) {
                          return _buildTextField(
                            controller: _confirmPasswordController,
                            hintText:
                                LocalizationService().t('confirm_password'),
                            icon: Icons.lock_outline,
                            obscureText: obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onPressed: () {
                                obscureConfirmPasswordNotifier.value =
                                    !obscureConfirmPassword;
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return LocalizationService()
                                    .t('please_confirm_password');
                              }
                              if (value != _passwordController.text) {
                                return LocalizationService()
                                    .t('passwords_not_match');
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: LocalizationService().t('phone'),
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return LocalizationService()
                                .t('please_enter_your_phone');
                          }
                          if (!RegExp(r'^01[0-2,5][0-9]{8}$').hasMatch(value)) {
                            return LocalizationService().t('invalid_phone');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  LocalizationService().t('create_account'),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LocalizationService().t('have_account'),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.labelSmall?.color,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, 'login');
                            },
                            child: Text(
                              LocalizationService().t('sign_in'),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(int index, String emoji, Color borderColor) {
    bool isSelected = _selectedAvatar == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatar = index;
        });
      },
      child: Container(
        width: isSelected ? 80 : 60,
        height: isSelected ? 80 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor.withValues(alpha: 0.2),
          border: Border.all(
            color: isSelected ? borderColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: isSelected ? 32 : 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            TextStyle(color: Theme.of(context).textTheme.labelSmall?.color),
        prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    obscurePasswordNotifier.dispose();
    obscureConfirmPasswordNotifier.dispose();
    LocalizationService().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }
}
