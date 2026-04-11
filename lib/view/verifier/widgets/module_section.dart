import 'package:flutter/material.dart';
import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/view/verifier/widgets/test_row.dart';
import 'package:nexus_cts/view/widgets/mini_chip.dart';

class ModuleSection extends StatelessWidget {
  final VerifierModule module;
  final List<VerifierTestCase> testCases;

  const ModuleSection({
    super.key,
    required this.module,
    required this.testCases,
  });

  @override
  Widget build(BuildContext context) {
    final color = module.failed > 0
        ? Colors.red
        : module.done
        ? Colors.green
        : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(color: color, width: 3),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                module.failed > 0
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              MiniChip(label: 'P:${module.passed}', color: Colors.green),
              const SizedBox(width: 6),
              MiniChip(label: 'F:${module.failed}', color: Colors.red),
              const SizedBox(width: 6),
              MiniChip(label: 'T:${module.totalTests}', color: Colors.grey),
            ],
          ),
        ),
        ...testCases.map((tc) => TestRow(testCase: tc)),
        const SizedBox(height: 4),
      ],
    );
  }
}
