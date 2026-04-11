import 'package:flutter/material.dart';
import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/view/widgets/info_chip.dart';

class ExecutionCard extends StatelessWidget {
  final VerifierExecution exec;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExecutionCard({
    super.key,
    required this.exec,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final passRate = exec.passRate;
    final color = passRate >= 95
        ? Colors.green
        : passRate >= 80
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exec.suitePlan ?? 'CTS Verifier',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (exec.suiteVersion != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        exec.suiteVersion!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  Chip(
                    label: Text(
                      '${passRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Remover',
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  InfoChip(
                    icon: Icons.check_circle,
                    label: '${exec.passed}',
                    color: Colors.green,
                  ),
                  InfoChip(
                    icon: Icons.cancel,
                    label: '${exec.failed}',
                    color: Colors.red,
                  ),
                  InfoChip(
                    icon: Icons.remove_circle,
                    label: '${exec.notExecuted}',
                    color: Colors.grey,
                  ),
                  InfoChip(
                    icon: Icons.grid_view,
                    label: '${exec.modulesDone}/${exec.modulesTotal}',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (exec.deviceSerial != null)
                Text(
                  'Serial: ${exec.deviceSerial}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (exec.buildFingerprint != null)
                Text(
                  'Build: ${exec.buildFingerprint}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (exec.startTime != null)
                Text(
                  'Início: ${exec.startTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
