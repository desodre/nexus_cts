import 'package:flutter/material.dart';
import 'package:nexus_cts/models/test_result.dart';
import 'package:nexus_cts/view/widgets/detail_text.dart';
import 'package:nexus_cts/view/widgets/format_helpers.dart';
import 'package:nexus_cts/view/widgets/info_chip.dart';

class ResultTile extends StatelessWidget {
  final SuiteResult result;

  const ResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final s = result.summary;
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
                  const Icon(Icons.folder, size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.folderName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatDate(result.modified),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (s != null) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    InfoChip(
                      icon: Icons.check_circle,
                      label: '${s.passed}',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    InfoChip(
                      icon: Icons.cancel,
                      label: '${s.failed}',
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    InfoChip(
                      icon: Icons.view_module,
                      label: '${s.modulesDone}/${s.modulesTotal}',
                      color: Colors.blueGrey,
                    ),
                    const Spacer(),
                    Text(
                      '${s.passRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: s.passRate >= 90
                            ? Colors.green
                            : s.passRate >= 70
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.total > 0 ? s.passed / s.total : 0,
                    minHeight: 6,
                    backgroundColor: Colors.red.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ),
              ],
              if (result.suitePlan != null ||
                  result.startTime != null ||
                  result.deviceSerial != null ||
                  result.buildFingerprint != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (result.suitePlan != null)
                      DetailText(
                        icon: Icons.assignment,
                        text: result.suitePlan!,
                      ),
                    if (result.startTime != null)
                      DetailText(icon: Icons.schedule, text: result.startTime!),
                    if (result.deviceSerial != null)
                      DetailText(
                        icon: Icons.phone_android,
                        text: result.deviceSerial!,
                      ),
                    if (result.buildFingerprint != null)
                      DetailText(
                        icon: Icons.fingerprint,
                        text: result.buildFingerprint!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
