import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movies/core/app_assets.dart';
import 'package:movies/cubit/search_cubit.dart';
import 'package:movies/cubit/states.dart';
import 'package:movies/services/localization_service.dart';

import '../widgets/movie_card.dart';

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit(),
      child: SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is SearchInitial) {
          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SvgPicture.asset(
                          AppAssets.search,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color),
                          decoration: InputDecoration(
                            hintText: LocalizationService().t('search_hint'),
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.color),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged: (query) {
                            context.read<SearchCubit>().searchMovies(query);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Empty State
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.emptySearch,
                        width: 124,
                        height: 124,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (state is SearchLoading) {
          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SvgPicture.asset(
                          AppAssets.search,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color),
                          decoration: InputDecoration(
                            hintText: LocalizationService().t('search_hint'),
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.color),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged: (query) {
                            context.read<SearchCubit>().searchMovies(query);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Loading
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          );
        }

        if (state is SearchError) {
          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SvgPicture.asset(
                          AppAssets.search,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color),
                          decoration: InputDecoration(
                            hintText: LocalizationService().t('search_hint'),
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.color),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged: (query) {
                            context.read<SearchCubit>().searchMovies(query);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Error
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    state.message,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
              ),
            ],
          );
        }

        if (state is SearchLoaded) {
          if (state.movies.isEmpty) {
            return CustomScrollView(
              slivers: [
                // Search Bar
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: SvgPicture.asset(
                            AppAssets.search,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                            decoration: InputDecoration(
                              hintText: LocalizationService().t('search_hint'),
                              hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.color),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            cursorColor: Theme.of(context).primaryColor,
                            onChanged: (query) {
                              context.read<SearchCubit>().searchMovies(query);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Empty Results
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppAssets.emptySearch,
                          width: 124,
                          height: 124,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SvgPicture.asset(
                          AppAssets.search,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color),
                          decoration: InputDecoration(
                            hintText: LocalizationService().t('search_hint'),
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.color),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged: (query) {
                            context.read<SearchCubit>().searchMovies(query);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Results Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
