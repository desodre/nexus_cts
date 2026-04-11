import 'package:flutter/material.dart';
import 'package:nexus_cts/models/test_result.dart';
import 'package:nexus_cts/view/home/widgets/result_tile.dart';
import 'package:nexus_cts/view/settings/settings_page.dart';
import 'package:nexus_cts/view/widgets/suite_icon_helper.dart';

class ResultsSection extends StatelessWidget {
  final bool loading;
  final bool noSuiteConfigured;
  final List<SuiteResult> results;
  final Map<String, List<SuiteResult>> groupedResults;
  final List<String> orderedGroupKeys;
  final VoidCallback onRefresh;

  const ResultsSection({
    super.key,
    required this.loading,
    required this.noSuiteConfigured,
    required this.results,
    required this.groupedResults,
    required this.orderedGroupKeys,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Resultados das Suítes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar resultados',
              onPressed: loading ? null : onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (noSuiteConfigured) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nenhum caminho de suíte configurado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                  onRefresh();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Ir para Configurações'),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Nenhum resultado encontrado nas suítes configuradas'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: orderedGroupKeys.map((suite) {
        final items = groupedResults[suite]!;
        final (IconData icon, Color color) = suiteIconData(
          items.first.suiteType,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(icon, color: color),
            title: Text(
              suite,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            subtitle: Text('${items.length} resultado(s)'),
            initiallyExpanded: true,
            children: items.map((r) => ResultTile(result: r)).toList(),
          ),
        );
      }).toList(),
    );
  }
}
