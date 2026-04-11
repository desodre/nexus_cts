import 'package:flutter/material.dart';

class ItsXmlScenesPanel extends StatelessWidget {
  final List<String> scenes;

  const ItsXmlScenesPanel({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ITS Scenes (extraídas do XML)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
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
                backgroundColor: Colors.blue[50],
                side: BorderSide(color: Colors.blue[200]!),
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
