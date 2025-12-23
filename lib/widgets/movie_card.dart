import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final Color? textColor;

  const MovieCard({
    super.key,
    required this.movie,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/movie_details', arguments: movie);
      },
      child: LayoutBuilder(builder: (context, constraints) {
        // Reserve space for title/year area based on font size and max lines
        const double titleFontSize = 12.0;
        const int maxTitleLines = 3;
        final double titleAreaHeight =
            (titleFontSize * 1.4) * maxTitleLines + 8;
        double posterHeight;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          posterHeight = (constraints.maxHeight - titleAreaHeight)
              .clamp(80.0, double.infinity);
        } else {
          // fallback: base on available width
          final width = MediaQuery.of(context).size.width * 0.45;
          posterHeight = width * 1.5; // portrait fallback
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: posterHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      movie.mediumCoverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/Empty.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    // Rating badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color.fromARGB(100, 0, 0, 0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              movie.rating.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.star_rounded,
                              color: AppAssets.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                height: (12.0 * 1.4) * maxTitleLines,
                child: Text(
                  movie.year != 0
                      ? '${movie.title} (${movie.year})'
                      : movie.title,
                  maxLines: maxTitleLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor ??
                        Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
