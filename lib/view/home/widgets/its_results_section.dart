import 'package:flutter/material.dart';
import 'package:nexus_cts/models/camera_its_result.dart';
import 'package:nexus_cts/view/home/widgets/its_tile.dart';

class ItsResultsSection extends StatelessWidget {
  final List<CameraItsResult> itsResults;
  final bool loadingItsResults;
  final bool loadingResults;
  final VoidCallback onRefresh;

  const ItsResultsSection({
    super.key,
    required this.itsResults,
    required this.loadingItsResults,
    required this.loadingResults,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Camera ITS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (loadingItsResults)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar resultados',
              onPressed: loadingResults ? null : onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (itsResults.isEmpty && !loadingItsResults)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Nenhum resultado Camera ITS encontrado em /tmp/',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(itsResults.map((r) => ItsTile(result: r))),
      ],
    );
  }
}
