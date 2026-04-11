import 'package:flutter/material.dart';
import 'package:nexus_cts/models/camera_its_result.dart';
import 'package:nexus_cts/view/home/widgets/test_detail_dialog.dart';
import 'package:nexus_cts/view/widgets/info_chip.dart';

class ItsSceneTile extends StatelessWidget {
  final ItsSceneResult scene;

  const ItsSceneTile({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.videocam, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    'cam${scene.camera} / ${scene.scene}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  InfoChip(
                    icon: Icons.check_circle,
                    label: '${scene.passed}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.cancel,
                    label: '${scene.failed}',
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.skip_next,
                    label: '${scene.skipped}',
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: scene.tests.map((t) {
                  final color = t.passed
                      ? Colors.green
                      : t.failed
                      ? Colors.red
                      : Colors.grey;
                  return GestureDetector(
                    onTap: t.detail != null
                        ? () => showTestDetailDialog(context, t)
                        : null,
                    child: Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: Icon(
                        t.passed
                            ? Icons.check_circle
                            : t.failed
                            ? Icons.cancel
                            : Icons.skip_next,
                        size: 16,
                        color: color,
                      ),
                      label: Text(
                        t.testName,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
