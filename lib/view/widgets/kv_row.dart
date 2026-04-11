import 'package:flutter/material.dart';

class KvRow extends StatelessWidget {
  final String label;
  final String? value;

  const KvRow({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(value!, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
