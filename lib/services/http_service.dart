import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../const/app_constants.dart';

/// Enhanced HTTP client with retry logic and timeout handling
class HttpService {
  static final HttpService _instance = HttpService._internal();

  factory HttpService() => _instance;

  HttpService._internal();

  final http.Client _client = http.Client();
  static const int _maxRetries = 3;

  /// Perform GET request with retry logic
  Future<http.Response> get(
    String url, {
    int retryCount = 0,
  }) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(
            AppConstants.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode >= 500 && retryCount < _maxRetries) {
        // Retry on server errors
        await Future.delayed(Duration(seconds: retryCount + 1));
        return get(url, retryCount: retryCount + 1);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}',
          response: response,
        );
      }
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return get(url, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  /// Parse JSON response safely
  static Map<String, dynamic> parseJsonResponse(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON response: $e');
    }
  }

  /// Parse list JSON response safely
  static List<dynamic> parseJsonListResponse(String body) {
    try {
      return json.decode(body) as List<dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON list response: $e');
    }
  }

  /// Close HTTP client
  void dispose() {
    _client.close();
  }
}

class HttpException implements Exception {
  final String message;
  final http.Response? response;

  HttpException(this.message, {this.response});

  @override
  String toString() => message;
}
