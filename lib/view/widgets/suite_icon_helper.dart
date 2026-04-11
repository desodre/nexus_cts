import 'package:flutter/material.dart';

/// Centraliza o mapeamento ícone/cor para cada tipo de suíte.
(IconData, Color) suiteIconData(String type) {
  return switch (type) {
    'CTS' => (Icons.verified, Colors.blue),
    'CTS-on-GSI' => (Icons.verified_user, Colors.indigo),
    'VTS' => (Icons.memory, Colors.deepPurple),
    'GTS' => (Icons.play_circle, Colors.teal),
    'GTS-Interactive' => (Icons.touch_app, Colors.cyan),
    'GTS-Root' => (Icons.admin_panel_settings, Colors.deepOrange),
    'STS' => (Icons.security, Colors.red),
    'CTS Verifier' => (Icons.checklist, Colors.orange),
    _ => (Icons.science, Colors.grey),
  };
}
