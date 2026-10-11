import 'package:flutter/material.dart';
import '../../../core/theme/atlas_theme.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.playerName,
    required this.distanceKm,
    required this.score,
    required this.isWinner,
    required this.color,
  });

  final String playerName;
  final double? distanceKm;
  final int score;
  final bool isWinner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? color : AtlasColors.line,
          width: isWinner ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            playerName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            distanceKm == null ? 'Нет ответа' : '${distanceKm!.round()} км',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AtlasColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score очк.',
            style: const TextStyle(
              fontSize: 12,
              color: AtlasColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
