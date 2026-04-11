import 'package:flutter/material.dart';

class OutputPanel extends StatelessWidget {
  final String? output;
  final bool running;
  final bool panelCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final ScrollController scrollController;

  const OutputPanel({
    super.key,
    this.output,
    required this.running,
    required this.panelCollapsed,
    required this.onToggleCollapse,
    required this.onStop,
    required this.onClear,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (output == null && !running) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Selecione suíte, dispositivos e modo de execução,\n'
              'depois clique em "Iniciar Execução".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  panelCollapsed ? Icons.chevron_right : Icons.chevron_left,
                ),
                tooltip: panelCollapsed
                    ? 'Mostrar painel'
                    : 'Expandir terminal',
                onPressed: onToggleCollapse,
              ),
              const Text(
                'Saída',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (running) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const Spacer(),
              if (running)
                TextButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop, color: Colors.red),
                  label: const Text(
                    'Parar',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Limpar',
                  onPressed: onClear,
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 0, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: SelectableText(
                output ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
