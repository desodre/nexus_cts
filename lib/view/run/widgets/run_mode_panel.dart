import 'package:flutter/material.dart';
import 'package:nexus_cts/models/run_mode.dart';

class RunModePanel extends StatelessWidget {
  final RunMode runMode;
  final ValueChanged<RunMode> onModeChanged;
  final String? selectedSuiteName;
  final List<String> availableResults;
  final String? selectedResult;
  final ValueChanged<String?> onResultChanged;
  final List<String> availableSubplans;
  final String? selectedSubplan;
  final ValueChanged<String?> onSubplanChanged;
  final TextEditingController moduleController;
  final TextEditingController extraArgsController;

  const RunModePanel({
    super.key,
    required this.runMode,
    required this.onModeChanged,
    this.selectedSuiteName,
    required this.availableResults,
    this.selectedResult,
    required this.onResultChanged,
    required this.availableSubplans,
    this.selectedSubplan,
    required this.onSubplanChanged,
    required this.moduleController,
    required this.extraArgsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modo de Execução',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RadioGroup<RunMode>(
          groupValue: runMode,
          onChanged: (v) {
            if (v != null) onModeChanged(v);
          },
          child: Column(
            children: [
              _modeRadio(
                RunMode.newRun,
                'Nova Run',
                Icons.play_arrow,
                'Executa a suíte completa',
              ),
              _modeRadio(
                RunMode.retest,
                'Retry / Re-teste',
                Icons.replay,
                'Re-executa testes que falharam',
              ),
              _modeRadio(
                RunMode.subplan,
                'Subplan',
                Icons.list_alt,
                'Executa um subplan específico',
              ),
            ],
          ),
        ),
        if (runMode == RunMode.retest) ...[
          const SizedBox(height: 12),
          if (selectedSuiteName == null)
            const Text(
              'Selecione uma suíte para listar os resultados.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else if (availableResults.isEmpty)
            const Text(
              'Nenhum resultado encontrado nesta suíte.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedResult,
              decoration: const InputDecoration(
                labelText: 'Resultado para Retry',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.history),
              ),
              items: availableResults
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onResultChanged,
            ),
        ],
        if (runMode == RunMode.subplan) ...[
          const SizedBox(height: 12),
          if (selectedSuiteName == null)
            const Text(
              'Selecione uma suíte para listar os subplans.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else if (availableSubplans.isEmpty)
            const Text(
              'Nenhum subplan encontrado nesta suíte.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedSubplan,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Subplan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.list_alt),
              ),
              items: availableSubplans
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: .clip),
                    ),
                  )
                  .toList(),
              onChanged: onSubplanChanged,
            ),
        ],
        const Divider(height: 32),
        const Text(
          'Opções Avançadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: moduleController,
          decoration: const InputDecoration(
            labelText: 'Módulo específico (-m)',
            border: OutlineInputBorder(),
            hintText: 'ex: CtsMediaTestCases',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: extraArgsController,
          decoration: const InputDecoration(
            labelText: 'Argumentos extras',
            border: OutlineInputBorder(),
            hintText: 'ex: --skip-preconditions',
          ),
        ),
      ],
    );
  }

  Widget _modeRadio(RunMode mode, String label, IconData icon, String desc) {
    return ListTile(
      leading: Radio<RunMode>(value: mode),
      title: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      onTap: () => onModeChanged(mode),
    );
  }
}
