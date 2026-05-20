import 'package:flutter/material.dart';

class BattleLogWidget extends StatelessWidget {
  final String logText;

  const BattleLogWidget({super.key, required this.logText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5A059), width: 1),
      ),
      child: Text(
        logText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFEFE6D4),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}