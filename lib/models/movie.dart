import 'package:movies/config/api_config.dart';

class Movie {
  final int id;
  final String url;
  final String imdbCode;
  final String title;
  final String titleEnglish;
  final String titleLong;
  final String slug;
  final int year;
  final double rating;
  final int runtime;
  final List<String> genres;
  final String summary;
  final String descriptionFull;
  final String synopsis;
  final String ytTrailerCode;
  final String language;
  final String mpaRating;
  final String backgroundImage;
  final String backgroundImageOriginal;
  final String smallCoverImage;
  final String mediumCoverImage;
  final String largeCoverImage;
  final String state;
  final List<Torrent> torrents;
  final String dateUploaded;
  final int dateUploadedUnix;
  final List<String> screenshots;
  final List<Cast> cast;
  final String? mediumScreenshot1;
  final String? mediumScreenshot2;
  final String? mediumScreenshot3;
  final String? largeScreenshot1;
  final String? largeScreenshot2;
  final String? largeScreenshot3;
  final int? likeCount;

  Movie({
    required this.id,
    required this.url,
    required this.imdbCode,
    required this.title,
    required this.titleEnglish,
    required this.titleLong,
    required this.slug,
    required this.year,
    required this.rating,
    required this.runtime,
    required this.genres,
    this.summary = '',
    this.descriptionFull = '',
    this.synopsis = '',
    this.ytTrailerCode = '',
    required this.language,
    this.mpaRating = '',
    required this.backgroundImage,
    required this.backgroundImageOriginal,
    required this.smallCoverImage,
    required this.mediumCoverImage,
    required this.largeCoverImage,
    required this.state,
    required this.torrents,
    required this.dateUploaded,
    required this.dateUploadedUnix,
    this.screenshots = const [],
    this.cast = const [],
    this.mediumScreenshot1,
    this.mediumScreenshot2,
    this.mediumScreenshot3,
    this.largeScreenshot1,
    this.largeScreenshot2,
    this.largeScreenshot3,
    this.likeCount,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      imdbCode: json['imdb_code'] ?? '',
      title: json['title'] ?? '',
      titleEnglish: json['title_english'] ?? '',
      titleLong: json['title_long'] ?? '',
      slug: json['slug'] ?? '',
      year: json['year'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      runtime: json['runtime'] ?? 0,
      genres: List<String>.from(json['genres'] ?? []),
      summary: json['summary'] ?? '',
      descriptionFull: json['description_full'] ?? '',
      synopsis: json['synopsis'] ?? '',
      ytTrailerCode: json['yt_trailer_code'] ?? '',
      language: json['language'] ?? '',
      mpaRating: json['mpa_rating'] ?? '',
      likeCount: (json['like_count'] as num?)?.toInt(),
      backgroundImage: json['background_image'] ?? '',
      backgroundImageOriginal: json['background_image_original'] ?? '',
      smallCoverImage: json['small_cover_image'] ?? '',
      mediumCoverImage: json['medium_cover_image'] ?? '',
      largeCoverImage: json['large_cover_image'] ?? '',
      state: json['state'] ?? '',
      torrents: (json['torrents'] as List?)
              ?.map((torrent) => Torrent.fromJson(torrent))
              .toList() ??
          [],
      dateUploaded: json['date_uploaded'] ?? '',
      dateUploadedUnix: json['date_uploaded_unix'] ?? 0,
      screenshots: [
        if (json['large_screenshot_image1'] != null)
          json['large_screenshot_image1'],
        if (json['large_screenshot_image2'] != null)
          json['large_screenshot_image2'],
        if (json['large_screenshot_image3'] != null)
          json['large_screenshot_image3'],
      ],
      cast:
          (json['cast'] as List?)?.map((x) => Cast.fromJson(x)).toList() ?? [],
      mediumScreenshot1: json['medium_screenshot_image1'],
      mediumScreenshot2: json['medium_screenshot_image2'],
      mediumScreenshot3: json['medium_screenshot_image3'],
      largeScreenshot1: json['large_screenshot_image1'],
      largeScreenshot2: json['large_screenshot_image2'],
      largeScreenshot3: json['large_screenshot_image3'],
    );
  }

  /// Create a Movie from TMDB list item (search / discover results)
  factory Movie.fromTmdbList(Map<String, dynamic> json) {
    final posterPath = json['poster_path'] as String?;
    final backdropPath = json['backdrop_path'] as String?;
    final releaseDate = json['release_date'] as String? ?? '';
    int year = 0;
    if (releaseDate.isNotEmpty) {
      year = int.tryParse(releaseDate.split('-').first) ?? 0;
    }
    // Convert TMDB genre IDs to human-readable names using ApiConfig
    List<String> genreNames = [];
    try {
      final ids =
          (json['genre_ids'] as List?)?.map((g) => g as int).toList() ?? [];
      for (var id in ids) {
        final entry = ApiConfig.tmdbGenreIds.entries.firstWhere(
            (e) => e.value == id,
            orElse: () => MapEntry(id.toString(), id));
        genreNames.add(entry.key);
      }
    } catch (_) {
      genreNames =
          (json['genre_ids'] as List?)?.map((g) => g.toString()).toList() ?? [];
    }

    return Movie(
      id: json['id'] ?? 0,
      url: '',
      imdbCode: '',
      title: json['title'] ?? json['name'] ?? '',
      titleEnglish: json['original_title'] ?? json['original_name'] ?? '',
      titleLong: json['title'] ?? '',
      slug: '',
      year: year,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      runtime: 0,
      genres: genreNames,
      summary: json['overview'] ?? '',
      descriptionFull: json['overview'] ?? '',
      synopsis: json['overview'] ?? '',
      ytTrailerCode: '',
      language: json['original_language'] ?? '',
      mpaRating: '',
      likeCount: (json['popularity'] as num?)?.toInt(),
      backgroundImage: backdropPath != null
          ? 'https://image.tmdb.org/t/p/original$backdropPath'
          : '',
      backgroundImageOriginal: backdropPath != null
          ? 'https://image.tmdb.org/t/p/original$backdropPath'
          : '',
      smallCoverImage: posterPath != null
          ? 'https://image.tmdb.org/t/p/w200$posterPath'
          : '',
      mediumCoverImage: posterPath != null
          ? 'https://image.tmdb.org/t/p/w342$posterPath'
          : '',
      largeCoverImage: posterPath != null
          ? 'https://image.tmdb.org/t/p/w500$posterPath'
          : '',
      state: '',
      torrents: [],
      dateUploaded: '',
      dateUploadedUnix: 0,
      screenshots: [],
      cast: [],
      mediumScreenshot1: null,
      mediumScreenshot2: null,
      mediumScreenshot3: null,
      largeScreenshot1: null,
      largeScreenshot2: null,
      largeScreenshot3: null,
    );
  }

  /// Create a Movie from TMDB details response (includes credits, videos, images)
  factory Movie.fromTmdbDetails(Map<String, dynamic> json) {
    final posterPath = json['poster_path'] as String?;
    final backdropPath = json['backdrop_path'] as String?;

    // Extract trailer (YouTube) code if available
    String ytCode = '';
    try {
      final videos = json['videos']?['results'] as List?;
      if (videos != null) {
        for (var v in videos) {
          if ((v['site'] == 'YouTube' || v['site'] == 'youtube') &&
              v['type'] == 'Trailer') {
            ytCode = v['key'] ?? '';
            break;
          }
        }
      }
    } catch (_) {}

    // Cast
    List<Cast> castList = [];
    try {
      final credits = json['credits']?['cast'] as List?;
      if (credits != null) {
        castList = credits
            .take(10)
            .map((c) => Cast(
                  name: c['name'] ?? '',
                  characterName: c['character'] ?? '',
                  urlSmallImage: c['profile_path'] != null
                      ? 'https://image.tmdb.org/t/p/w200${c['profile_path']}'
                      : '',
                  imdbCode: c['id']?.toString() ?? '',
                ))
            .toList();
      }
    } catch (_) {}

    final releaseDate = json['release_date'] as String? ?? '';
    int year = 0;
    if (releaseDate.isNotEmpty) {
      year = int.tryParse(releaseDate.split('-').first) ?? 0;
    }

    return Movie(
      id: json['id'] ?? 0,
      url: '',
      imdbCode: json['imdb_id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      titleEnglish: json['original_title'] ?? json['original_name'] ?? '',
      titleLong: json['title'] ?? '',
      slug: '',
      year: year,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      runtime: json['runtime'] ?? 0,
      genres: (json['genres'] as List?)
              ?.map((g) => g['name'] as String)
              .cast<String>()
              .toList() ??
          [],
      summary: json['overview'] ?? '',
      descriptionFull: json['overview'] ?? '',
      synopsis: json['overview'] ?? '',
      ytTrailerCode: ytCode,
      language: json['original_language'] ?? '',
      mpaRating: json['adult'] == true ? '18+' : '',
      likeCount: (json['popularity'] as num?)?.toInt(),
      backgroundImage: backdropPath != null
          ? 'https://image.tmdb.org/t/p/original$backdropPath'
          : '',
      backgroundImageOriginal: backdropPath != null
          ? 'https://image.tmdb.org/t/p/original$backdropPath'
          : '',
      smallCoverImage: posterPath != null
          ? 'https://image.tmdb.org/t/p/w200$posterPath'
          : '',
      mediumCoverImage: posterPath != null
          ? 'https://image.tmdb.org/t/p/w342$posterPath'
          : '',
      largeCoverImage: posterPath != null
          ? 'https://image.tmdb.org/t/p/w500$posterPath'
          : '',
      state: '',
      torrents: [],
      dateUploaded: json['release_date'] ?? '',
      dateUploadedUnix: 0,
      screenshots: [],
      cast: castList,
      mediumScreenshot1: null,
      mediumScreenshot2: null,
      mediumScreenshot3: null,
      largeScreenshot1: null,
      largeScreenshot2: null,
      largeScreenshot3: null,
    );
  }

  /// Convert movie to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'imdbCode': imdbCode,
      'title': title,
      'titleEnglish': titleEnglish,
      'titleLong': titleLong,
      'slug': slug,
      'year': year,
      'rating': rating,
      'runtime': runtime,
      'genres': genres,
      'summary': summary,
      'descriptionFull': descriptionFull,
      'synopsis': synopsis,
      'ytTrailerCode': ytTrailerCode,
      'language': language,
      'mpaRating': mpaRating,
      'backgroundImage': backgroundImage,
      'backgroundImageOriginal': backgroundImageOriginal,
      'smallCoverImage': smallCoverImage,
      'mediumCoverImage': mediumCoverImage,
      'largeCoverImage': largeCoverImage,
      'state': state,
      'dateUploaded': dateUploaded,
      'dateUploadedUnix': dateUploadedUnix,
      'likeCount': likeCount,
    };
  }

  /// Create movie from locally stored JSON
  factory Movie.fromLocalJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      imdbCode: json['imdbCode'] ?? '',
      title: json['title'] ?? '',
      titleEnglish: json['titleEnglish'] ?? '',
      titleLong: json['titleLong'] ?? '',
      slug: json['slug'] ?? '',
      year: json['year'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      runtime: json['runtime'] ?? 0,
      genres: List<String>.from(json['genres'] ?? []),
      summary: json['summary'] ?? '',
      descriptionFull: json['descriptionFull'] ?? '',
      synopsis: json['synopsis'] ?? '',
      ytTrailerCode: json['ytTrailerCode'] ?? '',
      language: json['language'] ?? '',
      mpaRating: json['mpaRating'] ?? '',
      backgroundImage: json['backgroundImage'] ?? '',
      backgroundImageOriginal: json['backgroundImageOriginal'] ?? '',
      smallCoverImage: json['smallCoverImage'] ?? '',
      mediumCoverImage: json['mediumCoverImage'] ?? '',
      largeCoverImage: json['largeCoverImage'] ?? '',
      state: json['state'] ?? '',
      torrents: [],
      dateUploaded: json['dateUploaded'] ?? '',
      dateUploadedUnix: json['dateUploadedUnix'] ?? 0,
      screenshots: [],
      cast: [],
      likeCount: json['likeCount'],
    );
  }

  /// Create a copy of this Movie with some fields replaced
  Movie copyWith({
    int? id,
    String? url,
    String? imdbCode,
    String? title,
    String? titleEnglish,
    String? titleLong,
    String? slug,
    int? year,
    double? rating,
    int? runtime,
    List<String>? genres,
    String? summary,
    String? descriptionFull,
    String? synopsis,
    String? ytTrailerCode,
    String? language,
    String? mpaRating,
    String? backgroundImage,
    String? backgroundImageOriginal,
    String? smallCoverImage,
    String? mediumCoverImage,
    String? largeCoverImage,
    String? state,
    List<Torrent>? torrents,
    String? dateUploaded,
    int? dateUploadedUnix,
    List<String>? screenshots,
    List<Cast>? cast,
    String? mediumScreenshot1,
    String? mediumScreenshot2,
    String? mediumScreenshot3,
    String? largeScreenshot1,
    String? largeScreenshot2,
    String? largeScreenshot3,
    dynamic likeCount,
  }) {
    return Movie(
      id: id ?? this.id,
      url: url ?? this.url,
      imdbCode: imdbCode ?? this.imdbCode,
      title: title ?? this.title,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      titleLong: titleLong ?? this.titleLong,
      slug: slug ?? this.slug,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      runtime: runtime ?? this.runtime,
      genres: genres ?? this.genres,
      summary: summary ?? this.summary,
      descriptionFull: descriptionFull ?? this.descriptionFull,
      synopsis: synopsis ?? this.synopsis,
      ytTrailerCode: ytTrailerCode ?? this.ytTrailerCode,
      language: language ?? this.language,
      mpaRating: mpaRating ?? this.mpaRating,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundImageOriginal:
          backgroundImageOriginal ?? this.backgroundImageOriginal,
      smallCoverImage: smallCoverImage ?? this.smallCoverImage,
      mediumCoverImage: mediumCoverImage ?? this.mediumCoverImage,
      largeCoverImage: largeCoverImage ?? this.largeCoverImage,
      state: state ?? this.state,
      torrents: torrents ?? this.torrents,
      dateUploaded: dateUploaded ?? this.dateUploaded,
      dateUploadedUnix: dateUploadedUnix ?? this.dateUploadedUnix,
      screenshots: screenshots ?? this.screenshots,
      cast: cast ?? this.cast,
      mediumScreenshot1: mediumScreenshot1 ?? this.mediumScreenshot1,
      mediumScreenshot2: mediumScreenshot2 ?? this.mediumScreenshot2,
      mediumScreenshot3: mediumScreenshot3 ?? this.mediumScreenshot3,
      largeScreenshot1: largeScreenshot1 ?? this.largeScreenshot1,
      largeScreenshot2: largeScreenshot2 ?? this.largeScreenshot2,
      largeScreenshot3: largeScreenshot3 ?? this.largeScreenshot3,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}

class Torrent {
  final String url;
  final String hash;
  final String quality;
  final String type;
  final String isRepack;
  final String videoCodec;
  final String bitDepth;
  final String audioChannels;
  final int seeds;
  final int peers;
  final String size;
  final int sizeBytes;
  final String dateUploaded;
  final int dateUploadedUnix;

  Torrent({
    required this.url,
    required this.hash,
    required this.quality,
    required this.type,
    required this.isRepack,
    required this.videoCodec,
    required this.bitDepth,
    required this.audioChannels,
    required this.seeds,
    required this.peers,
    required this.size,
    required this.sizeBytes,
    required this.dateUploaded,
    required this.dateUploadedUnix,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    return Torrent(
      url: json['url'] ?? '',
      hash: json['hash'] ?? '',
      quality: json['quality'] ?? '',
      type: json['type'] ?? '',
      isRepack: json['is_repack'] ?? '',
      videoCodec: json['video_codec'] ?? '',
      bitDepth: json['bit_depth'] ?? '',
      audioChannels: json['audio_channels'] ?? '',
      seeds: json['seeds'] ?? 0,
      peers: json['peers'] ?? 0,
      size: json['size'] ?? '',
      sizeBytes: json['size_bytes'] ?? 0,
      dateUploaded: json['date_uploaded'] ?? '',
      dateUploadedUnix: json['date_uploaded_unix'] ?? 0,
    );
  }
}

class Cast {
  final String name;
  final String characterName;
  final String urlSmallImage;
  final String imdbCode;

  Cast({
    required this.name,
    required this.characterName,
    required this.urlSmallImage,
    required this.imdbCode,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      name: json['name'] ?? '',
      characterName: json['character_name'] ?? '',
      urlSmallImage: json['url_small_image'] ?? '',
      imdbCode: json['imdb_code'] ?? '',
    );
  }
}
