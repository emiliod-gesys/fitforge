import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/custom_exercise.dart';

/// Persistencia local de ejercicios personalizados (sync-ready).
class CustomExerciseRepository {
  static const _dataFileName = 'custom_exercises.json';
  static const _imagesDirName = 'images';

  List<CustomExercise>? _cache;
  Directory? _rootDir;

  Future<Directory> _root() async {
    if (_rootDir != null) return _rootDir!;
    final docs = await getApplicationDocumentsDirectory();
    _rootDir = Directory(p.join(docs.path, 'custom_exercises'));
    if (!await _rootDir!.exists()) {
      await _rootDir!.create(recursive: true);
    }
    return _rootDir!;
  }

  Future<File> _dataFile() async {
    final root = await _root();
    return File(p.join(root.path, _dataFileName));
  }

  Future<Directory> _imagesDir() async {
    final root = await _root();
    final dir = Directory(p.join(root.path, _imagesDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<CustomExercise>> loadAll({bool includeDeleted = false}) async {
    if (_cache != null) {
      return _filterActive(_cache!, includeDeleted);
    }

    final file = await _dataFile();
    if (!await file.exists()) {
      _cache = [];
      return [];
    }

    try {
      final raw = jsonDecode(await file.readAsString()) as List;
      _cache = raw
          .whereType<Map<String, dynamic>>()
          .map(CustomExercise.fromJson)
          .toList();
    } catch (_) {
      _cache = [];
    }

    return _filterActive(_cache!, includeDeleted);
  }

  List<CustomExercise> _filterActive(List<CustomExercise> list, bool includeDeleted) {
    if (includeDeleted) return List.from(list);
    return list.where((e) => !e.isDeleted).toList();
  }

  Future<CustomExercise> create({
    required String name,
    required List<String> muscles,
    String? category,
    bool perArmWeight = false,
    XFile? photo,
  }) async {
    final all = await loadAll(includeDeleted: true);
    final active = all.where((e) => !e.isDeleted).length;
    if (active >= CustomExercise.maxPerUser) {
      throw StateError('max_custom_exercises');
    }

    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    String? imagePath;

    if (photo != null) {
      imagePath = await _saveImage(id, photo);
    }

    final exercise = CustomExercise(
      id: id,
      name: name.trim(),
      muscles: muscles,
      category: category,
      perArmWeight: perArmWeight,
      localImagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );

    all.add(exercise);
    await _persist(all);
    return exercise;
  }

  Future<void> delete(String id) async {
    final all = await loadAll(includeDeleted: true);
    final index = all.indexWhere((e) => e.id == id);
    if (index < 0) return;

    final existing = all[index];
    await _deleteImageFile(existing.localImagePath);

    all[index] = existing.copyWith(
      deletedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      localImagePath: null,
      syncState: CustomExerciseSyncState.pendingUpload,
    );

    await _persist(all);
  }

  Future<String> _saveImage(String id, XFile photo) async {
    final dir = await _imagesDir();
    final dest = File(p.join(dir.path, '$id.jpg'));
    await File(photo.path).copy(dest.path);
    return dest.path;
  }

  Future<void> _deleteImageFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _persist(List<CustomExercise> all) async {
    _cache = List.from(all);
    final file = await _dataFile();
    final encoded = jsonEncode(all.map((e) => e.toJson()).toList());
    await file.writeAsString(encoded);
  }

  void clearCache() => _cache = null;

  static bool isCustomExerciseId(String exerciseId) {
    return exerciseId.startsWith(CustomExercise.idPrefix);
  }

  static String? parseCustomId(String exerciseId) {
    if (!isCustomExerciseId(exerciseId)) return null;
    return exerciseId.substring(CustomExercise.idPrefix.length);
  }
}
