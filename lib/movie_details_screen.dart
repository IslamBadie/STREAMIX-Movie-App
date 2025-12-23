import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:movies/core/app_assets.dart';
import 'package:movies/cubit/movie_cubit.dart';
import 'package:movies/cubit/states.dart';
import 'package:movies/services/localization_service.dart';
import 'package:movies/widgets/actor_card.dart';
import 'package:movies/widgets/movie_card.dart';

import 'models/movie.dart';

class MovieDetailsScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieCubit()..fetchMovieDetails(movie.id),
      child: MovieDetailsView(initialMovie: movie),
    );
  }
}

class MovieDetailsView extends StatefulWidget {
  final Movie initialMovie;

  const MovieDetailsView({
    super.key,
    required this.initialMovie,
  });

  @override
  State<MovieDetailsView> createState() => _MovieDetailsViewState();
}

class _MovieDetailsViewState extends State<MovieDetailsView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) {
        if (state is MovieLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final movie = state is MovieLoaded ? state.movie : widget.initialMovie;
        final similarMovies = state is MovieLoaded ? state.similarMovies : [];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster + title overlay
                SizedBox(
                  height: 560,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          movie.largeCoverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              Container(color: Colors.grey[800]),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Theme.of(context).scaffoldBackgroundColor,
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: _launchTrailer,
                          child: SvgPicture.asset(AppAssets.playButton,
                              width: 88, height: 88),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 28,
                        child: Column(
                          children: [
                            Text(
                              movie.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${movie.year}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.color,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final history = prefs.getStringList('history') ?? [];
                          if (!history.contains(movie.id.toString())) {
                            history.add(movie.id.toString());
                            await prefs.setStringList('history', history);
                            // Save movie data locally for offline access
                            await prefs.setString(
                              'movie_json_${movie.id}',
                              jsonEncode(movie.toJson()),
                            );
                          }

                          // Update Firebase if user is logged in (optional)
                          if (FirebaseAuth.instance.currentUser != null) {
                            try {
                              // Save movie data to Firebase
                              final movieDataMap = (await FirebaseFirestore
                                              .instance
                                              .collection('users')
                                              .doc(FirebaseAuth
                                                  .instance.currentUser!.uid)
                                              .get())
                                          .data()?['movieData']
                                      as Map<String, dynamic>? ??
                                  {};
                              movieDataMap[movie.id.toString()] =
                                  movie.toJson();

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .update({
                                'history': history,
                                'movieData': movieDataMap,
                              }).timeout(const Duration(seconds: 2));
                            } catch (e) {
                              debugPrint(
                                  'Firebase sync skipped (non-critical): $e');
                            }
                          }

                          _launchTrailer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          LocalizationService().t('watch'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final prefs = snap.data!;
                          final watchList =
                              prefs.getStringList('watchlist') ?? [];
                          final isInWatchList =
                              watchList.contains(movie.id.toString());

                          return OutlinedButton.icon(
                            onPressed: () async {
                              final list =
                                  prefs.getStringList('watchlist') ?? [];
                              if (isInWatchList) {
                                list.remove(movie.id.toString());
                                // Remove local JSON cache
                                await prefs.remove('movie_json_${movie.id}');
                              } else {
                                list.add(movie.id.toString());
                                // Save movie data locally for offline access
                                await prefs.setString(
                                  'movie_json_${movie.id}',
                                  jsonEncode(movie.toJson()),
                                );
                              }
                              await prefs.setStringList('watchlist', list);

                              // Update Firebase if user is logged in (optional)
                              if (FirebaseAuth.instance.currentUser != null) {
                                try {
                                  final movieDataMap =
                                      (await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(FirebaseAuth.instance
                                                          .currentUser!.uid)
                                                      .get())
                                                  .data()?['movieData']
                                              as Map<String, dynamic>? ??
                                          {};
                                  if (!isInWatchList) {
                                    movieDataMap[movie.id.toString()] =
                                        movie.toJson();
                                  } else {
                                    movieDataMap.remove(movie.id.toString());
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      .update({
                                    'watchlist': list,
                                    'movieData': movieDataMap,
                                  }).timeout(const Duration(seconds: 2));
                                } catch (e) {
                                  debugPrint('Firebase sync skipped: $e');
                                }
                              }

                              setState(() {});
                            },
                            icon: Icon(isInWatchList ? Icons.check : Icons.add,
                                color: Theme.of(context).iconTheme.color),
                            label: Text(isInWatchList
                                ? LocalizationService()
                                    .t('remove_from_watchlist')
                                : LocalizationService().t('add_to_watchlist')),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(
                                  color: Theme.of(context).dividerColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final prefs = snap.data!;
                          final favorites =
                              prefs.getStringList('favorites') ?? [];
                          final isInFavorites =
                              favorites.contains(movie.id.toString());

                          return OutlinedButton.icon(
                            onPressed: () async {
                              final list =
                                  prefs.getStringList('favorites') ?? [];
                              if (isInFavorites) {
                                list.remove(movie.id.toString());
                                // Remove local JSON cache
                                await prefs.remove('movie_json_${movie.id}');
                              } else {
                                list.add(movie.id.toString());
                                // Save movie data locally for offline access
                                await prefs.setString(
                                  'movie_json_${movie.id}',
                                  jsonEncode(movie.toJson()),
                                );
                              }
                              await prefs.setStringList('favorites', list);

                              // Update Firebase if user is logged in (optional)
                              if (FirebaseAuth.instance.currentUser != null) {
                                try {
                                  final movieDataMap =
                                      (await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(FirebaseAuth.instance
                                                          .currentUser!.uid)
                                                      .get())
                                                  .data()?['movieData']
                                              as Map<String, dynamic>? ??
                                          {};
                                  if (!isInFavorites) {
                                    movieDataMap[movie.id.toString()] =
                                        movie.toJson();
                                  } else {
                                    movieDataMap.remove(movie.id.toString());
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth
                                          .instance.currentUser!.uid)
                                      .update({
                                    'favorites': list,
                                    'movieData': movieDataMap,
                                  }).timeout(const Duration(seconds: 2));
                                } catch (e) {
                                  debugPrint('Firebase sync skipped: $e');
                                }
                              }

                              setState(() {});
                            },
                            icon: Icon(
                                isInFavorites
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                color: isInFavorites
                                    ? Colors.red
                                    : Theme.of(context).iconTheme.color),
                            label: Text(isInFavorites
                                ? LocalizationService()
                                    .t('remove_from_favorites')
                                : LocalizationService().t('add_to_favorites')),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(
                                  color: Theme.of(context).dividerColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoChip(
                              icon: AppAssets.heart,
                              label: '${movie.likeCount ?? 0}'),
                          _InfoChip(
                              icon: AppAssets.time, label: '${movie.runtime}'),
                          _InfoChip(
                              icon: AppAssets.star, label: '${movie.rating}'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if ((movie.largeScreenshot1 ?? '').isNotEmpty ||
                          (movie.largeScreenshot2 ?? '').isNotEmpty ||
                          (movie.largeScreenshot3 ?? '').isNotEmpty) ...[
                        SectionHeading(
                            title: LocalizationService().t('screenshots')),
                        const SizedBox(height: 8),
                        if ((movie.largeScreenshot1 ?? '').isNotEmpty)
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(movie.largeScreenshot1!,
                                  height: 150, fit: BoxFit.cover)),
                        const SizedBox(height: 8),
                        if ((movie.largeScreenshot2 ?? '').isNotEmpty)
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(movie.largeScreenshot2!,
                                  height: 150, fit: BoxFit.cover)),
                        const SizedBox(height: 8),
                        if ((movie.largeScreenshot3 ?? '').isNotEmpty)
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(movie.largeScreenshot3!,
                                  height: 150, fit: BoxFit.cover)),
                      ],
                      const SizedBox(height: 14),
                      if (movie.descriptionFull.isNotEmpty) ...[
                        SectionHeading(
                            title: LocalizationService().t('summary')),
                        Text(
                          movie.descriptionFull,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              height: 1.5),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (movie.cast.isNotEmpty) ...[
                        SectionHeading(title: LocalizationService().t('cast')),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: movie.cast
                                  .map((a) => ActorCard(actor: a))
                                  .toList()),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if ((movie.genres).isNotEmpty) ...[
                        SectionHeading(
                            title: LocalizationService().t('genres')),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: movie.genres
                              .map((g) =>
                                  Chip(label: Text(LocalizationService().t(g))))
                              .toList(),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (similarMovies.isNotEmpty) ...[
                        SectionHeading(
                            title: LocalizationService().t('similar_movies')),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 0.65,
                          children: similarMovies
                              .map((m) => MovieCard(movie: m))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchTrailer() async {
    // Prefer the loaded movie from MovieCubit if available
    Movie movie;
    final state = context.read<MovieCubit>().state;
    if (state is MovieLoaded) {
      movie = state.movie;
    } else {
      movie = widget.initialMovie;
    }

    if (movie.ytTrailerCode.isNotEmpty) {
      final Uri url =
          Uri.parse('https://www.youtube.com/watch?v=${movie.ytTrailerCode}');
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        SvgPicture.asset(icon, width: 18, height: 18),
        const SizedBox(width: 8),
        Text(label)
      ]),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  const SectionHeading({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
