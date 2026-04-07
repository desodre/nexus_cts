import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VenvEntry {
  /// Apelido livre (ex: its_py311, camera_its)
  String name;

  /// Caminho absoluto da venv (ex: /home/user/.venvs/its)
  String path;

  VenvEntry({required this.name, required this.path});

  String get normalizedPath => path.replaceAll(RegExp(r'/+$'), '');

  String get pythonBin => '$normalizedPath/bin/python';

  String get displayLabel => '$name — $path';

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
      };

  factory VenvEntry.fromJson(Map<String, dynamic> json) {
    return VenvEntry(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }
}

class VenvStorage {
  static const _key = 'configured_venvs';

  static Future<List<VenvEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => VenvEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<VenvEntry> venvs) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(venvs.map((v) => v.toJson()).toList());
    await prefs.setString(_key, json);
  }
}
