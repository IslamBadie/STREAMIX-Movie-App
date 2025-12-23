import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final file = File('assets/model_ai/movie_data.json');
  if (!await file.exists()) {
    stderr.writeln('movie_data.json not found at assets/model_ai/');
    return;
  }

  final List data = json.decode(await file.readAsString()) as List;

  final keywords = [
    'anime',
    'robot',
    'food',
    'game',
    'mecha',
    'romcom',
    'cyberpunk',
    'heist',
    'biopic',
    'zombie',
    'ghibli',
    'music',
    'dance',
    'puzzle',
    'mask'
  ];

  for (final k in keywords) {
    final q = k.toLowerCase();
    final matches = data.where((e) {
      final title = (e['title'] ?? '').toString().toLowerCase();
      final tags = (e['tags'] ?? '').toString().toLowerCase();
      return title.contains(q) || tags.contains(q);
    }).toList();

    final postered = matches.where((e) {
      final p = e['posterUrl'] ?? e['poster'] ?? '';
      return p != null && p.toString().trim().isNotEmpty;
    }).toList();

    stderr.writeln(
        'Keyword: "$k" → matches: ${matches.length}, postered: ${postered.length}');
    for (var i = 0; i < (matches.length < 10 ? matches.length : 10); i++) {
      final m = matches[i];
      final id = m['movie_id'] ?? m['id'] ?? '';
      final p = m['posterUrl'] ?? m['poster'] ?? '';
      stderr.writeln(
          '  - ${m['title']}${id != '' ? ' ($id)' : ''}${p.toString().trim().isNotEmpty ? ' [poster]' : ''}');
    }
    stderr.writeln('');
  }

  stderr.writeln('Done');
}
