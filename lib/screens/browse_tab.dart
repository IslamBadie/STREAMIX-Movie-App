import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies/core/app_assets.dart';
import 'package:movies/services/localization_service.dart';
import 'package:movies/cubit/states.dart';

import '../cubit/browse_cubit.dart';
import '../widgets/movie_card.dart';

class BrowseTab extends StatelessWidget {
  final String initialCategory;

  const BrowseTab({super.key, this.initialCategory = 'Action'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BrowseCubit()..fetchMovies(initialCategory),
      child: BrowseView(),
    );
  }
}

class BrowseView extends StatelessWidget {
  final List<String> categories = const [
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Romance',
    'Thriller',
    'Adventure',
    'Animation',
    'Biography',
    'Crime',
    'Documentary',
    'Family',
    'Fantasy',
    'History',
    'Mystery',
    'Sci-Fi',
    'Sport',
    'War',
    'Western',
  ];

  const BrowseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Categories
            SizedBox(
              height: 50,
              child: BlocBuilder<BrowseCubit, BrowseState>(
                builder: (context, state) {
                  final currentCategory =
                      state is BrowseLoaded ? state.currentCategory : 'All';

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == currentCategory;

                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            LocalizationService().t(category),
                            style: TextStyle(
                                fontSize: 20,
                                color: isSelected
                                    ? AppAssets.black
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color),
                          ),
                          onSelected: (_) {
                            context
                                .read<BrowseCubit>()
                                .changeCategory(category);
                          },
                          backgroundColor: isSelected
                              ? AppAssets.primary
                              : Colors.transparent,
                          selectedColor: AppAssets.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppAssets.primary,
                              width: 2,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppAssets.black
                                : AppAssets.primary,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Movies Grid
            Expanded(
              child: BlocBuilder<BrowseCubit, BrowseState>(
                builder: (context, state) {
                  if (state is BrowseLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (state is BrowseError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (state is BrowseLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<BrowseCubit>()
                            .fetchMovies(state.currentCategory);
                        await Future.delayed(Duration(milliseconds: 400));
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                            context.read<BrowseCubit>().loadMoreMovies();
                          }
                          return false;
                        },
                        child: GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 140,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: state.movies.length,
                          itemBuilder: (context, index) {
                            return MovieCard(movie: state.movies[index]);
                          },
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Text(
                      'No movies found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
