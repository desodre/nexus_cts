import 'package:flutter/material.dart';
import 'package:nexus_cts/models/camera_its_result.dart';
import 'package:nexus_cts/view/home/widgets/its_scene_tile.dart';
import 'package:nexus_cts/view/widgets/detail_text.dart';
import 'package:nexus_cts/view/widgets/format_helpers.dart';
import 'package:open_dir/open_dir.dart';

class ItsTile extends StatelessWidget {
  final CameraItsResult result;

  const ItsTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.orange),
          onPressed: () {
            //Open a folder from this result in file explorer
            //This only works on desktop platforms
            final local = result.fullPath;
            final openDirPlugin = OpenDir();
            openDirPlugin.openNativeDir(path: local);
          },
        ),
        title: Text(
          result.folderName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Pass: ${result.totalPassed}  Fail: ${result.totalFailed}  '
          'Skip: ${result.totalSkipped}  —  ${result.passRate.toStringAsFixed(1)}%',
        ),
        trailing: Text(
          formatDate(result.modified),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          if (result.dutSerial != null || result.buildFingerprint != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 16,
                children: [
                  if (result.dutSerial != null)
                    DetailText(
                      icon: Icons.phone_android,
                      text: result.dutSerial!,
                    ),
                  if (result.buildFingerprint != null)
                    DetailText(
                      icon: Icons.fingerprint,
                      text: result.buildFingerprint!,
                    ),
                ],
              ),
            ),
          ...result.scenes.map((sc) => ItsSceneTile(scene: sc)),
        ],
      ),
    );
  }
}
