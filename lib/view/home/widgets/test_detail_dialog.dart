import 'package:flutter/material.dart';
import 'package:nexus_cts/models/camera_its_result.dart';
import 'package:nexus_cts/view/widgets/format_helpers.dart';
import 'package:nexus_cts/view/widgets/kv_row.dart';
import 'package:nexus_cts/view/widgets/section_title.dart';
import 'package:nexus_cts/view/widgets/summary_badge.dart';

void showTestDetailDialog(BuildContext context, ItsTestEntry t) {
  final d = t.detail!;
  final resultColor = d.result == 'PASS'
      ? Colors.green
      : d.result == 'FAIL'
      ? Colors.red
      : Colors.grey;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            d.result == 'PASS' ? Icons.check_circle : Icons.cancel,
            color: resultColor,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(t.testName, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              d.result ?? '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 750,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionTitle(
                'Informações do Teste',
                icon: Icons.info_outline,
              ),
              KvRow(label: 'Test Name', value: d.testName),
              KvRow(label: 'Test Class', value: d.testClass),
              KvRow(label: 'Signature', value: d.signature),
              if (d.beginTime != null)
                KvRow(label: 'Início', value: formatTimestamp(d.beginTime)),
              if (d.endTime != null)
                KvRow(label: 'Fim', value: formatTimestamp(d.endTime)),
              if (d.duration != null)
                KvRow(label: 'Duração', value: '${d.duration!.inSeconds}s'),
              const Divider(height: 24),

              const SectionTitle('Sumário', icon: Icons.bar_chart),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  SummaryBadge(
                    label: 'Passed',
                    count: d.passedCount,
                    color: Colors.green,
                  ),
                  SummaryBadge(
                    label: 'Failed',
                    count: d.failedCount,
                    color: Colors.red,
                  ),
                  SummaryBadge(
                    label: 'Error',
                    count: d.errorCount,
                    color: Colors.orange,
                  ),
                  SummaryBadge(
                    label: 'Executed',
                    count: d.executedCount,
                    color: Colors.blue,
                  ),
                  SummaryBadge(
                    label: 'Skipped',
                    count: d.skippedCount,
                    color: Colors.grey,
                  ),
                ],
              ),
              const Divider(height: 24),

              if (d.terminationSignal != null) ...[
                const SectionTitle(
                  'Termination Signal',
                  icon: Icons.warning_amber_rounded,
                ),
                SelectableText(
                  d.terminationSignal!,
                  style: TextStyle(color: Colors.red.shade300),
                ),
                const Divider(height: 24),
              ],

              if (d.details != null) ...[
                const SectionTitle('Detalhes', icon: Icons.description),
                SelectableText(d.details!),
                const Divider(height: 24),
              ],

              if (d.stacktrace != null) ...[
                const SectionTitle('Stacktrace', icon: Icons.terminal),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    d.stacktrace!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                const Divider(height: 24),
              ],

              if (d.devices.isNotEmpty) ...[
                SectionTitle(
                  'Controller Info (${d.devices.length} dispositivo${d.devices.length > 1 ? 's' : ''})',
                  icon: Icons.phone_android,
                ),
                const SizedBox(height: 8),
                ...d.devices.asMap().entries.map((e) {
                  final idx = e.key;
                  final dev = e.value;
                  final label = idx == 0 ? 'DUT' : 'Tablet';
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label — ${dev.serial ?? "N/A"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        KvRow(label: 'Model', value: dev.model),
                        KvRow(label: 'Build ID', value: dev.buildId),
                        KvRow(label: 'Product', value: dev.buildProduct),
                        KvRow(label: 'Build Type', value: dev.buildType),
                        KvRow(label: 'SDK Version', value: dev.sdkVersion),
                        KvRow(
                          label: 'Characteristics',
                          value: dev.characteristics,
                        ),
                        if (dev.buildFingerprint != null)
                          KvRow(
                            label: 'Fingerprint',
                            value: dev.buildFingerprint,
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
