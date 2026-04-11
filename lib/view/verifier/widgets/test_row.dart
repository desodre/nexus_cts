import 'package:flutter/material.dart';
import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/view/widgets/detail_block.dart';

class TestRow extends StatelessWidget {
  final VerifierTestCase testCase;

  const TestRow({super.key, required this.testCase});

  @override
  Widget build(BuildContext context) {
    final isPassed = testCase.result == 'pass';
    final isFailed = testCase.result == 'fail';
    final color = isPassed
        ? Colors.green
        : isFailed
        ? Colors.red
        : Colors.grey;
    final icon = isPassed
        ? Icons.check
        : isFailed
        ? Icons.close
        : Icons.remove;
    final hasDetails = testCase.message != null || testCase.stacktrace != null;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: hasDetails
          ? ExpansionTile(
              tilePadding: const EdgeInsets.only(left: 32, right: 12),
              leading: Icon(icon, color: color, size: 16),
              title: Text(testCase.name, style: const TextStyle(fontSize: 13)),
              trailing: Text(
                testCase.result.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                if (testCase.message != null)
                  DetailBlock(title: 'Mensagem', content: testCase.message!),
                if (testCase.stacktrace != null)
                  DetailBlock(
                    title: 'Stacktrace',
                    content: testCase.stacktrace!,
                  ),
              ],
            )
          : ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 12),
              leading: Icon(icon, color: color, size: 16),
              title: Text(testCase.name, style: const TextStyle(fontSize: 13)),
              trailing: Text(
                testCase.result.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              dense: true,
            ),
    );
  }
}
