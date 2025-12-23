import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:movies/cubit/browse_cubit.dart';
import 'package:movies/cubit/states.dart';
import 'package:movies/screens/chatbot_view.dart';
import 'package:movies/screens/browse_tab.dart';
import 'package:movies/widgets/movie_card.dart';
import 'package:movies/services/localization_service.dart';

import '../core/app_assets.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late BrowseCubit _browseCubit;

  @override
  void initState() {
    super.initState();
    _browseCubit = BrowseCubit()..fetchMovies('Action');
  }

  @override
  void dispose() {
    _browseCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider.value(
        value: _browseCubit,
        child: RefreshIndicator(
          onRefresh: () async {
            await _browseCubit.fetchMovies('Action');
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildCarousel(context),
                _buildCategorySection(context, 'Action'),
                _buildCategorySection(context, 'Comedy'),
                _buildCategorySection(context, 'Drama'),
                _buildCategorySection(context, 'Horror'),
                _buildCategorySection(context, 'Thriller'),
                _buildCategorySection(context, 'Adventure'),
                _buildCategorySection(context, 'Fantasy'),
              ],
            ),
          ),
        ),
      ),

      // Add Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open chatbot page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatBotView(),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.smart_toy),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    // Use a dedicated cubit for trending/popular carousel
    return BlocProvider(
      create: (_) => BrowseCubit()..fetchTrendingMovies(),
      child: BlocBuilder<BrowseCubit, BrowseState>(
        builder: (context, state) {
          if (state is BrowseLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is BrowseLoaded) {
            final movies = state.movies;
            ValueNotifier<int> currentIndexNotifier = ValueNotifier(0);

            return SizedBox(
              height: 480,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Background Poster
                  ValueListenableBuilder<int>(
                    valueListenable: currentIndexNotifier,
                    builder: (context, index, child) {
                      return Image.network(
                        movies.isNotEmpty ? movies[index].largeCoverImage : '',
                        fit: BoxFit.cover,
                      );
                    },
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(18, 19, 18, 0.8),
                          Color.fromRGBO(18, 19, 18, 0.6),
                          Color.fromRGBO(18, 19, 18, 1.0),
                        ],
                        stops: [0, 0.47, 1.0],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 24,
                    left: 24,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LocalizationService().t('available_now'),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    right: 24,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LocalizationService().t('watch_now'),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  // Carousel centered vertically
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: CarouselSlider(
                        options: CarouselOptions(
                          height: 360,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.55,
                          autoPlay: false,
                          onPageChanged: (index, reason) {
                            currentIndexNotifier.value = index;
                          },
                        ),
                        items: movies.map((movie) {
                          return Builder(
                            builder: (BuildContext context) {
                              return MovieCard(
                                movie: movie,
                                textColor: Colors.white,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('Failed to load movies'));
          }
        },
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String category) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LocalizationService().t(category),
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                            AppAssets.white,
                        fontSize: 24)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BrowseTab(initialCategory: category),
                      ),
                    );
                  },
                  child: Text(LocalizationService().t('see_more'),
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ],
            ),
          ),

          // Horizontal Movie List
          SizedBox(
            height: 260,
            width: double.infinity,
            child: BlocProvider(
              create: (_) => BrowseCubit()..fetchMovies(category),
              child: BlocBuilder<BrowseCubit, BrowseState>(
                builder: (context, state) {
                  if (state is BrowseLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (state is BrowseLoaded) {
                    final filteredMovies = state.movies;
                    if (filteredMovies.isEmpty) {
                      return Center(
                          child: Text(LocalizationService().t('no_results')));
                    }
                    return ListView.separated(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredMovies.length,
                      separatorBuilder: (context, index) => SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 140,
                          child: MovieCard(movie: filteredMovies[index]),
                        );
                      },
                    );
                  } else if (state is BrowseError) {
                    return Center(child: Text(state.message));
                  } else {
                    return Center(
                        child: Text(LocalizationService().t('no_results')));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
