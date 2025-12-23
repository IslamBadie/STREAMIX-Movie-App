import 'package:flutter/material.dart';
import 'package:movies/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movies/services/theme_service.dart';
import 'package:movies/services/cache_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  late LocalizationService _localizationService;
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _localizationService = LocalizationService();
    _themeService = ThemeService();
    _isDarkMode = _themeService.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_localizationService.t('settings')),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Language Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizationService.t('language'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _localizationService.setLocale(const Locale('en'));
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _localizationService.isArabic
                              ? Colors.grey[700]
                              : const Color.fromARGB(255, 156, 121, 5),
                        ),
                        child: const Text(
                          'English',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _localizationService.setLocale(const Locale('ar'));
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _localizationService.isArabic
                              ? const Color.fromARGB(255, 156, 121, 5)
                              : Colors.grey[700],
                        ),
                        child: const Text(
                          'العربية',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Theme Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizationService.t('theme'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(_localizationService.t('darkMode')),
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    // Don't wait for this to complete - let it happen in background
                    _themeService.setDarkMode(value);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Cache Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizationService.t('cache'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ctx = context;
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (ctx) => AlertDialog(
                              title:
                                  Text(_localizationService.t('clear_history')),
                              content: Text(_localizationService
                                  .t('clear_history_confirmation')),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child:
                                        Text(_localizationService.t('cancel'))),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(_localizationService.t('yes'))),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setStringList('history', []);

                            // Update Firebase (optional - doesn't block if failed)
                            if (FirebaseAuth.instance.currentUser != null) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .update({'history': []}).timeout(
                                  const Duration(seconds: 3),
                                  onTimeout: () {
                                    debugPrint('Firebase update timeout');
                                  },
                                );
                              } catch (e) {
                                // Silent fail - app works without Firebase
                                debugPrint(
                                    'Firebase sync failed (non-critical): $e');
                              }
                            }

                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(_localizationService
                                      .t('history_cleared'))));
                            }
                          }
                        },
                        icon: Icon(Icons.history_toggle_off),
                        label: Text(_localizationService.t('clear_history')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ctx = context;
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (ctx) => AlertDialog(
                              title:
                                  Text(_localizationService.t('clear_cache')),
                              content: Text(_localizationService
                                  .t('clear_cache_confirmation')),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child:
                                        Text(_localizationService.t('cancel'))),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(_localizationService.t('yes'))),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await CacheService().clearAllCache();
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(_localizationService
                                      .t('cache_cleared'))));
                            }
                          }
                        },
                        icon: Icon(Icons.delete_forever),
                        label: Text(_localizationService.t('clear_cache')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
