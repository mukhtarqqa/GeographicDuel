import 'package:flutter/material.dart';
import '../../../core/theme/atlas_theme.dart';

class HealthOverview extends StatelessWidget {
  const HealthOverview({
    super.key,
    required this.playerName,
    required this.playerHealth,
    required this.opponentName,
    required this.opponentHealth,
  });

  final String playerName;
  final int playerHealth;
  final String opponentName;
  final int opponentHealth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '$playerName: $playerHealth HP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AtlasColors.green),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$opponentName: $opponentHealth HP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AtlasColors.rust),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (playerHealth / 6000).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: AtlasColors.green,
                  backgroundColor: const Color(0xffdce2d5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (opponentHealth / 6000).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: AtlasColors.rust,
                  backgroundColor: const Color(0xffdce2d5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
