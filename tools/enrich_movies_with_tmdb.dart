import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Usage: set TMDB_API_KEY env var then run:
// dart run tools/enrich_movies_with_tmdb.dart

Future<void> main() async {
  final apiKey = Platform.environment['TMDB_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln(
        'Please set TMDB_API_KEY environment variable before running.');
    return;
  }

  final file = File('assets/model_ai/movie_data.json');
  if (!await file.exists()) {
    stderr.writeln('movie_data.json not found at assets/model_ai/');
    return;
  }

  final backup = File('assets/model_ai/movie_data.json.bak');
  if (!await backup.exists()) {
    await backup.writeAsString(await file.readAsString());
    stderr.writeln('Backup created at assets/model_ai/movie_data.json.bak');
  }

  final List movies = json.decode(await file.readAsString()) as List;
  final baseUrl = 'https://api.themoviedb.org/3';
  final imageBase = 'https://image.tmdb.org/t/p/w342';

  int updated = 0;
  for (var i = 0; i < movies.length; i++) {
    final m = movies[i] as Map<String, dynamic>;
    final title = (m['title'] ?? '').toString();
    final posterExisting = (m['posterUrl'] ?? m['poster'] ?? '').toString();
    if (posterExisting.trim().isNotEmpty) continue;

    try {
      final q = Uri.encodeQueryComponent(title);
      final url =
          Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$q&page=1');
      final resp = await http.get(url).timeout(Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final posterPath = first['poster_path'];
          if (posterPath != null && posterPath.toString().trim().isNotEmpty) {
            m['posterUrl'] = '$imageBase$posterPath';
            updated++;
            if (updated % 50 == 0) {
              stderr.writeln('Updated $updated posters...');
            }
          }
        }
      } else {
        stderr.writeln(
            'TMDB search failed for "$title" status=${resp.statusCode}');
      }
    } catch (e) {
      stderr.writeln('Error searching TMDB for "$title": $e');
    }

    // small delay to be polite
    await Future.delayed(Duration(milliseconds: 250));
  }

  if (updated > 0) {
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(movies));
    stderr.writeln('Wrote updated movie_data.json ($updated posters added).');
  } else {
    stderr.writeln('No posters were updated.');
  }
}
