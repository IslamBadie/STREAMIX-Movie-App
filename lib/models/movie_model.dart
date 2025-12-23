class Movie {
  final int id;
  final String title;
  final String tags;
  final double rating;
  final int year;
  final int runtime;
  final List<String> genres;
  final String posterUrl;

  Movie({
    required this.id,
    required this.title,
    required this.tags,
    this.rating = 0.0,
    this.year = 0,
    this.runtime = 0,
    this.genres = const [],
    this.posterUrl = '',
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['movie_id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      tags: json['tags'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      year: json['year'] as int? ?? 0,
      runtime: json['runtime'] as int? ?? 0,
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      posterUrl: json['poster_url'] as String? ?? '',
    );
  }
}
