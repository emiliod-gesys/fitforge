import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lectura/escritura atómica de JSON en el directorio de documentos de la app.
abstract final class OfflineJsonFile {
  static Directory? _rootDir;

  static Future<Directory> root() async {
    if (_rootDir != null) return _rootDir!;
    final docs = await getApplicationDocumentsDirectory();
    _rootDir = Directory(p.join(docs.path, 'offline'));
    if (!await _rootDir!.exists()) {
      await _rootDir!.create(recursive: true);
    }
    return _rootDir!;
  }

  static Future<File> file(String name) async {
    final dir = await root();
    return File(p.join(dir.path, name));
  }

  static Future<Map<String, dynamic>> readMap(String name) async {
    final f = await file(name);
    if (!await f.exists()) return {};
    try {
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<List<dynamic>> readList(String name) async {
    final f = await file(name);
    if (!await f.exists()) return [];
    try {
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is List) return decoded;
    } catch (_) {}
    return [];
  }

  static Future<void> writeMap(String name, Map<String, dynamic> data) async {
    final f = await file(name);
    await f.writeAsString(jsonEncode(data), flush: true);
  }

  static Future<void> writeList(String name, List<dynamic> data) async {
    final f = await file(name);
    await f.writeAsString(jsonEncode(data), flush: true);
  }
}
