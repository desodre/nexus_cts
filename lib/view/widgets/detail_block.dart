import 'package:flutter/material.dart';

class DetailBlock extends StatelessWidget {
  final String title;
  final String content;

  const DetailBlock({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}
