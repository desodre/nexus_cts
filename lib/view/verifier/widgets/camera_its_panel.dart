import 'package:flutter/material.dart';

class CameraItsPanel extends StatelessWidget {
  final List<String> scenes;
  final String? logPath;

  const CameraItsPanel({super.key, required this.scenes, this.logPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scenes com falha — ${logPath ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${scenes.length} scene(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: scenes.map((scene) {
              return Chip(
                label: Text(scene, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.red[50],
                side: BorderSide(color: Colors.red[200]!),
                avatar: const Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: Colors.red,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
