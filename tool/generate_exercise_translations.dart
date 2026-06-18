// Genera assets/data/exercise_translations.json desde wger (ES + EN).
// Ejecutar: dart run tool/generate_exercise_translations.dart
//
// Para ejercicios sin traducción ES en wger, traduce el nombre EN → ES (Google público).

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _wgerBase = 'https://wger.de/api/v2';
const _outPath = 'assets/data/exercise_translations.json';
const _translateDelayMs = 120;

Future<void> main() async {
  final client = http.Client();
  try {
    stdout.writeln('Descargando ejercicios de wger…');
    final items = await _fetchAllExercises(client);
    stdout.writeln('Total: ${items.length}');

    final out = <String, dynamic>{};
    var autoTranslated = 0;
    var skipped = 0;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id'] as int?;
      if (id == null) continue;

      final translations = item['translations'] as List? ?? [];
      var enName = '';
      var enDesc = '';
      String? esName;
      String? esDesc;

      for (final raw in translations) {
        if (raw is! Map<String, dynamic>) continue;
        final lang = raw['language'];
        final name = (raw['name'] as String? ?? '').trim();
        final desc = _stripHtml(raw['description'] as String? ?? '');
        if (lang == 2) {
          enName = name.isNotEmpty ? name : enName;
          if (desc.isNotEmpty) enDesc = desc;
        } else if (lang == 4) {
          if (name.isNotEmpty) esName = name;
          if (desc.isNotEmpty) esDesc = desc;
        }
      }

      if (enName.isEmpty) {
        skipped++;
        continue;
      }

      if (esName == null || esName.isEmpty) {
        esName = await _translateEnToEs(client, enName);
        autoTranslated++;
        if ((esDesc == null || esDesc.isEmpty) && enDesc.isNotEmpty) {
          esDesc = await _translateEnToEs(client, _truncate(enDesc, 400));
        }
        await Future<void>.delayed(const Duration(milliseconds: _translateDelayMs));
      }

      out['$id'] = {
        'es': {
          'name': esName,
          'description': esDesc ?? '',
        },
        'en': {
          'name': enName,
          'description': enDesc,
        },
      };

      if ((i + 1) % 50 == 0) {
        stdout.writeln('  ${i + 1}/${items.length}…');
      }
    }

    final dir = Directory('assets/data');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    await File(_outPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(out),
    );

    stdout.writeln('');
    stdout.writeln('Guardado: $_outPath');
    stdout.writeln('Entradas: ${out.length}');
    stdout.writeln('Traducciones ES auto-generadas: $autoTranslated');
    stdout.writeln('Omitidos (sin EN): $skipped');
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> _fetchAllExercises(http.Client client) async {
  final all = <Map<String, dynamic>>[];
  var offset = 0;
  const limit = 100;

  while (true) {
    final uri = Uri.parse('$_wgerBase/exerciseinfo/').replace(
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
    );
    final response = await client.get(uri);
    if (response.statusCode != 200) break;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];
    if (results.isEmpty) break;

    for (final item in results) {
      if (item is Map<String, dynamic>) all.add(item);
    }

    if (data['next'] == null) break;
    offset += limit;
  }

  return all;
}

String _stripHtml(String html) {
  return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _truncate(String text, int max) {
  if (text.length <= max) return text;
  return '${text.substring(0, max)}…';
}

Future<String> _translateEnToEs(http.Client client, String text) async {
  if (text.trim().isEmpty) return text;
  try {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=en&tl=es&dt=t&q=${Uri.encodeComponent(text)}',
    );
    final response = await client.get(uri);
    if (response.statusCode != 200) return text;

    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty) return text;

    final segments = data[0];
    if (segments is! List) return text;

    final buffer = StringBuffer();
    for (final seg in segments) {
      if (seg is List && seg.isNotEmpty) {
        buffer.write(seg[0]);
      }
    }
    final translated = buffer.toString().trim();
    return translated.isNotEmpty ? translated : text;
  } catch (_) {
    return text;
  }
}
