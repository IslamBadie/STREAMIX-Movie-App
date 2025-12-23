import 'package:flutter/material.dart';
import 'package:movies/screens/avatar_selection_screen.dart';
import 'package:movies/screens/login_screen.dart';
import 'package:movies/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateProfileScreen extends StatefulWidget {
  static const routeName = "update";
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'not_selected';

  String _currentAvatarPath =
      'assets/images/avatar.png'; // default avatar image

  // Original values for comparison
  late String _originalName;
  late String _originalPhone;
  late String _originalEmail;
  late String _originalAbout;
  late DateTime? _originalDateOfBirth;
  late String _originalGender;
  late String _originalAvatar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // load user data when screen initializes
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _originalName = prefs.getString('user_name') ?? 'User';
        _nameController.text = _originalName;

        _originalPhone = prefs.getString('user_phone') ?? '';
        _phoneController.text = _originalPhone;

        _originalEmail = prefs.getString('user_email') ?? '';
        _emailController.text = _originalEmail;

        _originalAvatar =
            prefs.getString('user_avatar') ?? 'assets/images/avatar.png';
        _currentAvatarPath = _originalAvatar;

        _originalAbout = prefs.getString('about_me') ?? '';
        _aboutController.text = _originalAbout;

        final dobStr = prefs.getString('date_of_birth');
        _originalDateOfBirth = null;
        if (dobStr != null && dobStr.isNotEmpty) {
          try {
            _originalDateOfBirth = DateTime.parse(dobStr);
            _dateOfBirth = _originalDateOfBirth;
          } catch (_) {}
        }

        _originalGender = prefs.getString('gender') ?? 'not_selected';
        _gender = _originalGender;
        _isLoading = false;
      });
    }
  }

  // Save user data to SharedPreferences and Firestore
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_phone', _phoneController.text);
    await prefs.setString('user_avatar', _currentAvatarPath);
    await prefs.setString('about_me', _aboutController.text);
    if (_dateOfBirth != null) {
      await prefs.setString('date_of_birth', _dateOfBirth!.toIso8601String());
    }
    await prefs.setString('gender', _gender);

    // Also save to Firestore so changes sync across devices
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'user_avatar': _currentAvatarPath,
          'about_me': _aboutController.text,
          'gender': _gender,
          if (_dateOfBirth != null)
            'date_of_birth': _dateOfBirth!.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error updating user data in Firestore: $e');
    }
  }

  // Change email function
  Future<void> _changeEmail() async {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService().t('change_email')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: LocalizationService().t('new_email'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: LocalizationService().t('enter_password'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService().t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocalizationService().t('change')),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Validate inputs
    if (newEmailController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('enter_new_email')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(newEmailController.text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('invalid_email')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('enter_password')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().t('user_not_found')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Re-authenticate with current password
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().t('incorrect_password')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Change email
      await user.verifyBeforeUpdateEmail(newEmailController.text);

      // Update in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', newEmailController.text);

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'email': newEmailController.text,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('email_verification_sent')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _emailController.text = newEmailController.text;
          _originalEmail = newEmailController.text;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().t('error')}: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().t('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<bool> _reauthenticateWithPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('user_not_found')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    final TextEditingController pwController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService().t('reenter_password')),
        content: TextField(
          controller: pwController,
          obscureText: true,
          decoration: InputDecoration(
              hintText: LocalizationService().t('enter_your_password')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(LocalizationService().t('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(LocalizationService().t('yes'))),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      final credential = EmailAuthProvider.credential(
          email: user.email!, password: pwController.text);
      await user.reauthenticateWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('authentication_success')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = LocalizationService().t('incorrect_password');
        if (e.code == 'user-not-found') {
          errorMessage = LocalizationService().t('user_not_found');
        } else if (e.code == 'wrong-password') {
          errorMessage = LocalizationService().t('incorrect_password');
        } else if (e.code == 'too-many-requests') {
          errorMessage = LocalizationService().t('too_many_attempts');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().t('error')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  // Change password function
  Future<void> _changePassword() async {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService().t('change_password')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: LocalizationService().t('current_password'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: LocalizationService().t('new_password'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPwController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: LocalizationService().t('confirm_password'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService().t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocalizationService().t('change')),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Validate inputs
    if (currentPwController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('enter_current_password')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (newPwController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('enter_new_password')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (newPwController.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('password_min_length')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (newPwController.text != confirmPwController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('passwords_not_match')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().t('user_not_found')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Re-authenticate with current password
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPwController.text,
        );
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationService().t('incorrect_password')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Change password
      await user.updatePassword(newPwController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().t('password_changed')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().t('error')}: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().t('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).iconTheme.color),
            onPressed: () {
              // Don't save - just go back
              Navigator.pop(context);
            },
          ),
          title: Text(
            LocalizationService().t('pick_avatar'),
            style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Tappable profile avatar
                      GestureDetector(
                        onTap: () async {
                          final selectedAvatar = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AvatarSelectionScreen(),
                            ),
                          );

                          if (selectedAvatar != null) {
                            setState(() {
                              _currentAvatarPath = selectedAvatar;
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: Image.asset(
                              _currentAvatarPath, // use the current avatar path
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person,
                                    size: 80, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        hintText: LocalizationService().t('enter_your_name'),
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 15),

                      // Phone field
                      _buildTextField(
                        controller: _phoneController,
                        hintText: LocalizationService().t('enter_phone_number'),
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),

                      // Email (read-only)
                      _buildTextField(
                        controller: _emailController,
                        hintText: LocalizationService().t('email'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false, // Display only
                      ),
                      const SizedBox(height: 15),

                      // About me
                      _buildTextField(
                        controller: _aboutController,
                        hintText: LocalizationService().t('about_me'),
                        icon: Icons.info,
                      ),
                      const SizedBox(height: 15),

                      // Date of Birth & Gender
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfBirth ?? DateTime(1990),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateOfBirth = picked;
                                  });
                                }
                              },
                              child: Text(_dateOfBirth == null
                                  ? LocalizationService().t('date_of_birth')
                                  : _dateOfBirth!
                                      .toLocal()
                                      .toIso8601String()
                                      .split('T')
                                      .first),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              items: [
                                DropdownMenuItem(
                                  value: 'not_selected',
                                  child: Text(
                                    LocalizationService().t('select_gender'),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                    value: 'male',
                                    child:
                                        Text(LocalizationService().t('male'))),
                                DropdownMenuItem(
                                    value: 'female',
                                    child: Text(
                                        LocalizationService().t('female'))),
                              ],
                              onChanged: (v) => setState(() {
                                _gender = v ?? 'not_selected';
                              }),
                              decoration: InputDecoration(
                                labelText: LocalizationService().t('gender'),
                                hintText:
                                    LocalizationService().t('select_gender'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Update Data button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _saveUserData();
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context, {
                              'name': _nameController.text,
                              'avatarPath': _currentAvatarPath,
                            });
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  LocalizationService()
                                      .t('changes_saved_successfully'),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDD835),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            LocalizationService().t('update_data'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Change Password button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            LocalizationService().t('change_password'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Change Email button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changeEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            LocalizationService().t('change_email'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete Account button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Show confirmation dialog before deleting account
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                    LocalizationService().t('delete_account')),
                                content: Text(LocalizationService()
                                    .t('delete_account_confirmation')),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(
                                          LocalizationService().t('cancel'))),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child:
                                          Text(LocalizationService().t('yes'))),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              // Always require password verification before deletion
                              final reauthOk =
                                  await _reauthenticateWithPassword();
                              if (!reauthOk) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocalizationService()
                                          .t('reauth_failed')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocalizationService()
                                          .t('account_delete_error')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              final ctx = context;
                              try {
                                // 1. Delete user data from Firestore
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .delete();

                                // 2. Delete Firebase Authentication account
                                await user.delete();

                                // 3. Clear local preferences
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.clear();
                                await prefs.setBool('showHome', false);

                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    // ignore: use_build_context_synchronously
                                    ctx,
                                    LoginScreen.routeName,
                                    (Route<dynamic> route) => false,
                                  );
                                  ScaffoldMessenger.of(
                                          ctx) // ignore: use_build_context_synchronously
                                      .showSnackBar(
                                    // ignore: use_build_context_synchronously
                                    SnackBar(
                                      content: Text(LocalizationService()
                                          .t('account_deleted')),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${LocalizationService().t('account_delete_error')}: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            LocalizationService().t('delete_account'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color),
          hintText: hintText,
          hintStyle:
              TextStyle(color: Theme.of(context).textTheme.labelSmall?.color),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }
}
