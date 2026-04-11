import 'package:flutter/material.dart';
import 'package:nexus_cts/models/run_mode.dart';
import 'package:nexus_cts/models/venv_entry.dart';

class VerifierActionPanel extends StatelessWidget {
  final VerifierAction action;
  final ValueChanged<VerifierAction> onActionChanged;
  final List<VenvEntry> venvs;
  final int? selectedVenvIndex;
  final ValueChanged<int?> onVenvChanged;
  final String cameraId;
  final ValueChanged<String> onCameraIdChanged;
  final TextEditingController scenesController;

  const VerifierActionPanel({
    super.key,
    required this.action,
    required this.onActionChanged,
    required this.venvs,
    this.selectedVenvIndex,
    required this.onVenvChanged,
    required this.cameraId,
    required this.onCameraIdChanged,
    required this.scenesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ação',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RadioGroup<VerifierAction>(
          groupValue: action,
          onChanged: (v) {
            if (v != null) onActionChanged(v);
          },
          child: Column(
            children: [
              _actionRadio(
                VerifierAction.installApks,
                'Instalar APKs',
                Icons.install_mobile,
                'Instala todos os APKs do CTS Verifier',
              ),
              _actionRadio(
                VerifierAction.cameraIts,
                'Camera ITS',
                Icons.camera_alt,
                'Executa os testes Camera ITS',
              ),
              _actionRadio(
                VerifierAction.cameraWebcamTest,
                'Camera Webcam Test',
                Icons.videocam,
                'Executa o CameraWebcamTest',
              ),
            ],
          ),
        ),
        if (action == VerifierAction.cameraIts ||
            action == VerifierAction.cameraWebcamTest) ...[
          const Divider(height: 24),
          const Text(
            'Python Venv',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (venvs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Nenhuma venv configurada.\nAdicione em Configurações.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: selectedVenvIndex,
              decoration: const InputDecoration(
                labelText: 'Virtual Environment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.terminal),
              ),
              items: venvs.asMap().entries.map((e) {
                final v = e.value;
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    v.name.isNotEmpty ? v.name : v.path,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onVenvChanged,
            ),
        ],
        if (action == VerifierAction.cameraIts) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: cameraId,
            decoration: const InputDecoration(
              labelText: 'Camera',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.camera_alt),
            ),
            items: const [
              DropdownMenuItem(value: '0', child: Text('0')),
              DropdownMenuItem(value: '0.3', child: Text('0.3')),
              DropdownMenuItem(value: '0.5', child: Text('0.5')),
              DropdownMenuItem(value: '1', child: Text('1')),
            ],
            onChanged: (v) {
              if (v != null) onCameraIdChanged(v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: scenesController,
            decoration: const InputDecoration(
              labelText: 'Scenes (opcional)',
              border: OutlineInputBorder(),
              hintText: 'ex: scene1,scene0',
              prefixIcon: Icon(Icons.photo_library),
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionRadio(
    VerifierAction act,
    String label,
    IconData icon,
    String desc,
  ) {
    return ListTile(
      leading: Radio<VerifierAction>(value: act),
      title: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      onTap: () => onActionChanged(act),
    );
  }
}
