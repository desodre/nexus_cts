import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SuiteEntry {
  /// Apelido livre dado pelo usuário (ex: 16_r1.3_pab)
  String name;

  /// Nome real da suíte: CTS, VTS, GTS, etc.
  String type;

  String path;

  SuiteEntry({required this.name, required this.type, required this.path});

  /// Caminho sem barra final (evita caminhos com //).
  String get normalizedPath => path.replaceAll(RegExp(r'/+$'), '');

  Map<String, dynamic> toJson() => {'name': name, 'type': type, 'path': path};

  factory SuiteEntry.fromJson(Map<String, dynamic> json) {
    return SuiteEntry(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }

  String get displayLabel => '$name ($type) — $path';
}

class SuiteStorage {
  static const _key = 'configured_suites';

  static Future<List<SuiteEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SuiteEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<SuiteEntry> suites) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(suites.map((s) => s.toJson()).toList());
    await prefs.setString(_key, json);
  }
}
