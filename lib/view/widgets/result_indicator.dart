import 'package:flutter/material.dart';
import 'package:nexus_cts/models/camera_its_result.dart';

class ResultIndicator extends StatelessWidget {
  const ResultIndicator({
    super.key,
    required this.resultColor,
    required this.d,
  });

  final MaterialColor resultColor;
  final ItsTestDetail d;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
