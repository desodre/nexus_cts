import 'package:flutter/material.dart';
import 'package:nexus_cts/view/settings/settings_page.dart';

class NoSuiteWarning extends StatelessWidget {
  final VoidCallback onReturn;

  const NoSuiteWarning({super.key, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 56,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum caminho de suíte configurado.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Defina o local das suítes em Configurações.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              onReturn();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Ir para Configurações'),
          ),
        ],
      ),
    );
  }
}
