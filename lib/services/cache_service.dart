import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Service for managing cache with custom configuration
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() => _instance;

  CacheService._internal();

  late final CacheManager _movieCacheManager = CacheManager(
    Config(
      'movieCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 500,
    ),
  );

  late final CacheManager _imageCacheManager = CacheManager(
    Config(
      'imageCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 1000,
    ),
  );

  /// Get cached file for movie data
  Future<String?> getMovieCache(String key) async {
    try {
      final file = await _movieCacheManager.getFileFromCache(key);
      if (file == null) return null;
      final bytes = await file.file.readAsBytes();
      // Decode using utf8 allowing malformed sequences, then strip control chars
      try {
        String decoded = utf8.decode(bytes, allowMalformed: true);
        // Remove control characters except common whitespace (\n, \r, \t)
        decoded =
            decoded.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ' ');
        return decoded;
      } catch (_) {
        // Fallback: try latin1
        try {
          final decoded = latin1.decode(bytes);
          return decoded;
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }

  /// Save movie data to cache
  Future<void> saveMovieCache(String key, String data) async {
    try {
      await _movieCacheManager.putFile(
        key,
        Uint8List.fromList(data.codeUnits),
        fileExtension: 'json',
      );
    } catch (e) {
      // Silently fail - cache loss is not critical
    }
  }

  /// Get cached image file
  Future<String?> getImageCachePath(String url) async {
    try {
      final file = await _imageCacheManager.getSingleFile(url);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      await _movieCacheManager.emptyCache();
      await _imageCacheManager.emptyCache();
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear movie cache
  Future<void> clearMovieCache() async {
    try {
      await _movieCacheManager.emptyCache();
    } catch (e) {
      // Silently fail
    }
  }
}
