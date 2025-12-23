import 'package:flutter/material.dart';
import 'package:movies/services/http_service.dart';
import 'package:movies/services/error_handler.dart';
import 'package:movies/services/cache_service.dart';
import 'package:movies/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movies/models/movie.dart';
import 'package:movies/widgets/movie_card.dart';
import 'package:movies/services/localization_service.dart';
import 'package:movies/screens/settings_screen.dart';
import 'package:movies/screens/login_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  static const routeName = "prof";
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _userName = 'Loading...';
  String _userAvatar = 'assets/images/avatar.png';
  String _aboutMe = '';

  List<String> _watchListIds = [];
  List<String> _historyIds = [];
  List<String> _favoritesIds = [];
  List<Movie> watchListMovies = [];
  List<Movie> historyMovies = [];
  List<Movie> favoritesMovies = [];
  bool _isLoadingMovies = true;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    LocalizationService().localeNotifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      _loadUserData();
      _isInitialLoad = false;
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            await prefs.setString('user_name', userData['name'] ?? '');
            await prefs.setString('user_email', userData['email'] ?? '');
            await prefs.setString('user_phone', userData['phone'] ?? '');
            await prefs.setString('user_avatar',
                userData['user_avatar'] ?? 'assets/images/avatar.png');
            await prefs.setString('about_me', userData['about_me'] ?? '');

            if (userData['date_of_birth'] != null &&
                userData['date_of_birth'].toString().isNotEmpty) {
              await prefs.setString(
                  'date_of_birth', userData['date_of_birth'].toString());
            }

            await prefs.setString(
                'gender', userData['gender'] ?? 'not_selected');

            final watchlist = List<String>.from(userData['watchlist'] ?? []);
            final history = List<String>.from(userData['history'] ?? []);
            final favorites = List<String>.from(userData['favorites'] ?? []);

            await prefs.setStringList('watchlist', watchlist);
            await prefs.setStringList('history', history);
            await prefs.setStringList('favorites', favorites);

            // Sync movie data from Firebase
            await _syncMovieDataFromFirebase(userData, prefs);

            debugPrint('User data synced from Firebase');
          }
        }
      } catch (e) {
        debugPrint('Firebase sync optional (using local data): $e');
      }
    }

    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userAvatar =
          prefs.getString('user_avatar') ?? 'assets/images/avatar.png';
      _aboutMe = prefs.getString('about_me') ?? '';
      _watchListIds =
          (prefs.getStringList('watchlist') ?? []).reversed.toList();
      _historyIds = (prefs.getStringList('history') ?? []).reversed.toList();
      _favoritesIds =
          (prefs.getStringList('favorites') ?? []).reversed.toList();
      _isLoadingMovies = true;
    });

    try {
      final results = await Future.wait([
        _getMoviesFromIds(_watchListIds),
        _getMoviesFromIds(_historyIds),
        _getMoviesFromIds(_favoritesIds),
      ]);

      if (mounted) {
        setState(() {
          watchListMovies = results[0];
          historyMovies = results[1];
          favoritesMovies = results[2];
          _isLoadingMovies = false;
        });
      }
    } catch (e) {
      ErrorHandler.logError('Profile', 'Error loading movies: $e');
      if (mounted) {
        setState(() {
          _isLoadingMovies = false;
        });
      }
    }
  }

  Future<List<Movie>> _getMoviesFromIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final HttpService httpService = HttpService();
    final cache = CacheService();
    final apiKey = ApiConfig.effectiveTmdbApiKey;
    final prefs = await SharedPreferences.getInstance();

    final futures = ids.map((id) async {
      final int movieId = int.tryParse(id) ?? 0;
      if (movieId == 0) {
        debugPrint('Invalid movie ID: $id');
        return null;
      }

      final cacheKey = 'movie_$movieId';

      try {
        // 1. Try to get from local JSON cache first
        final localJsonKey = 'movie_json_$movieId';
        final localJson = prefs.getString(localJsonKey);
        if (localJson != null) {
          try {
            final data = jsonDecode(localJson) as Map<String, dynamic>;
            final movie = Movie.fromLocalJson(data);
            debugPrint('Loaded movie $movieId from local cache');
            return movie;
          } catch (e) {
            debugPrint('Error parsing local JSON for movie $movieId: $e');
          }
        }

        // 2. Try cache manager
        final cached = await cache.getMovieCache(cacheKey);
        if (cached != null) {
          try {
            final data = HttpService.parseJsonResponse(cached);
            if (data.containsKey('success') && data['success'] == false) {
              debugPrint('Cached error for movie $movieId');
              return null;
            }
            var movieData = data['data']?['movie'];
            movieData ??= data;
            if (movieData != null && movieData is Map<String, dynamic>) {
              final movie = Movie.fromTmdbDetails(movieData);
              // Save to local JSON cache
              await prefs.setString(localJsonKey, jsonEncode(movie.toJson()));
              return movie;
            }
          } catch (e) {
            debugPrint('Error parsing cached data for movie $movieId: $e');
          }
        }

        // 3. Try API if key is available
        if (apiKey.isEmpty) {
          debugPrint('API key is empty for movie $movieId');
          return null;
        }

        final response = await httpService.get(
          '${ApiConfig.tmdbBaseUrl}/movie/$movieId?api_key=$apiKey&append_to_response=videos,credits',
        );

        if (response.statusCode == 200) {
          final data = HttpService.parseJsonResponse(response.body);

          if (data.containsKey('success') && data['success'] == false) {
            debugPrint(
                'API error for movie $movieId: ${data['status_message']}');
            return null;
          }

          if (data['id'] == null) {
            debugPrint('Movie data missing ID for movie $movieId');
            return null;
          }

          try {
            final movie = Movie.fromTmdbDetails(data);
            // Save to both cache manager and local JSON cache
            await cache
                .saveMovieCache(cacheKey, response.body)
                .catchError((_) {});
            await prefs.setString(localJsonKey, jsonEncode(movie.toJson()));
            debugPrint('Fetched and cached movie $movieId from API');
            return movie;
          } catch (e) {
            debugPrint('Error creating Movie object for $movieId: $e');
            return null;
          }
        } else {
          debugPrint('Failed to fetch movie $movieId: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        debugPrint('Exception loading movie $movieId: $e');
        return null;
      }
    }).toList();

    final results = await Future.wait(futures, eagerError: false);
    final movies = results.whereType<Movie>().toList();
    debugPrint('Loaded ${movies.length} out of ${ids.length} movies');
    return movies;
  }

  /// Sync movie data from Firebase to local storage
  Future<void> _syncMovieDataFromFirebase(
    Map<String, dynamic> userData,
    SharedPreferences prefs,
  ) async {
    try {
      // Get movie data from Firebase if available
      final movieDataMap =
          (userData['movieData'] as Map<String, dynamic>?) ?? {};

      // Sync each movie's data locally
      for (var entry in movieDataMap.entries) {
        final movieId = entry.key;
        final movieJson = entry.value;

        if (movieJson != null && movieJson is Map<String, dynamic>) {
          try {
            final localJsonKey = 'movie_json_$movieId';
            await prefs.setString(localJsonKey, jsonEncode(movieJson));
            debugPrint('Synced movie data from Firebase: $movieId');
          } catch (e) {
            debugPrint('Error syncing movie $movieId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing movie data from Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // Profile Info Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: Image.asset(
                              _userAvatar,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person,
                                    size: 60, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                        Expanded(child: SizedBox.shrink()),
                        IconButton(
                          icon: Icon(Icons.settings,
                              color: Theme.of(context).iconTheme.color),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        _userName,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_aboutMe.isNotEmpty)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _aboutMe,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.labelSmall?.color,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // Action Buttons Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, 'update').then((_) {
                            _loadUserData();
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.black),
                        label: Text(
                          LocalizationService().t('edit_profile'),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDD835),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ctx = context;
                          try {
                            await FirebaseAuth.instance.signOut();
                          } catch (_) {}

                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            // ignore: use_build_context_synchronously
                            ctx,
                            LoginScreen.routeName,
                            (Route<dynamic> route) => false,
                          );
                        },
                        icon:
                            const Icon(Icons.exit_to_app, color: Colors.white),
                        label: Text(
                          LocalizationService().t('exit'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Spacing
            SliverToBoxAdapter(
              child: const SizedBox(height: 20),
            ),
            // TabBar - Pinned at top when scrolling
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor:
                      Theme.of(context).textTheme.labelSmall?.color,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal, fontSize: 16),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.list_alt),
                      text: LocalizationService().t('watch_list'),
                    ),
                    Tab(
                      icon: const Icon(Icons.history),
                      text: LocalizationService().t('history'),
                    ),
                    Tab(
                      icon: const Icon(Icons.favorite),
                      text: LocalizationService().t('favorites'),
                    ),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMovieListView(
              watchListMovies,
              LocalizationService().t('watch_list'),
            ),
            _buildMovieListView(
              historyMovies,
              LocalizationService().t('history'),
            ),
            _buildMovieListView(
              favoritesMovies,
              LocalizationService().t('favorites'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieListView(List<Movie> movies, String title) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text('(${movies.length})',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        if (_isLoadingMovies)
          SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          )
        else if (movies.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Image.asset(
                'assets/images/Empty.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          )
        else
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoadingMovies = true;
                });
                _isInitialLoad = false;
                await _loadUserData();
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.6,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/movie_details',
                        arguments: movie,
                      ).then((_) => _loadUserData());
                    },
                    onLongPress: () {
                      _showDeleteConfirmationDialog(movie, title);
                    },
                    child: MovieCard(movie: movie),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Show confirmation dialog for deleting a movie from a list
  void _showDeleteConfirmationDialog(Movie movie, String listType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            LocalizationService().t('confirm_delete'),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          content: Text(
            '${LocalizationService().t('remove_from')} "$listType"?\n${movie.title}',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                LocalizationService().t('cancel'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.labelSmall?.color,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _removeMovieFromList(movie, listType);
              },
              child: Text(
                LocalizationService().t('delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Remove a movie from the specified list
  Future<void> _removeMovieFromList(Movie movie, String listType) async {
    // Get messenger reference before async operations
    final messenger = ScaffoldMessenger.of(context);

    try {
      final prefs = await SharedPreferences.getInstance();
      String listKey = '';

      // Determine which list to update
      if (listType == LocalizationService().t('watch_list')) {
        listKey = 'watchlist';
        _watchListIds.remove(movie.id.toString());
      } else if (listType == LocalizationService().t('history')) {
        listKey = 'history';
        _historyIds.remove(movie.id.toString());
      } else if (listType == LocalizationService().t('favorites')) {
        listKey = 'favorites';
        _favoritesIds.remove(movie.id.toString());
      }

      if (listKey.isEmpty) return;

      // Get current list
      List<String> list = prefs.getStringList(listKey) ?? [];
      list.remove(movie.id.toString());

      // Update local storage
      await prefs.setStringList(listKey, list);

      // Remove movie JSON cache
      await prefs.remove('movie_json_${movie.id}');

      // Update Firebase if user is logged in
      if (FirebaseAuth.instance.currentUser != null) {
        try {
          final movieDataMap = (await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get())
                  .data()?['movieData'] as Map<String, dynamic>? ??
              {};
          movieDataMap.remove(movie.id.toString());

          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            listKey: list,
            'movieData': movieDataMap,
          }).timeout(const Duration(seconds: 2));

          debugPrint('Movie ${movie.id} removed from $listKey in Firebase');
        } catch (e) {
          debugPrint('Firebase update error: $e');
        }
      }

      // Reload data to refresh UI
      if (mounted) {
        await _loadUserData();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${movie.title} ${LocalizationService().t('removed_successfully')}',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.logError('Profile', 'Error removing movie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().t('error_occurred'),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    LocalizationService().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  FloatingActionButton get floatingActionButton => FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      );
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
