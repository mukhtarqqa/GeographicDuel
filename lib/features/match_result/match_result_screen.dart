import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/player_state.dart';
import '../widgets/primary_button.dart';

class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({
    super.key,
    required this.player,
    required this.opponent,
    required this.totalRounds,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  final PlayerState player;
  final PlayerState opponent;
  final int totalRounds;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  bool get playerWon => player.health > opponent.health;

  @override
  Widget build(BuildContext context) {
    final ratingDiff = playerWon ? 24 : -18;

    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy or Skull icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: playerWon
                        ? const Color(0xfff6ffed)
                        : const Color(0xfffff1f0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: playerWon
                          ? const Color(0xff52c41a)
                          : const Color(0xffff4d4f),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (playerWon ? Colors.green : Colors.red)
                            .withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      playerWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      size: 46,
                      color: playerWon
                          ? const Color(0xff52c41a)
                          : const Color(0xffff4d4f),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Match Outcome Headline
                Text(
                  playerWon ? 'БЛЕСТЯЩАЯ ПОБЕДА!' : 'ПОРАЖЕНИЕ В ДУЭЛИ',
                  style: AtlasTheme.editorial(
                    32,
                    color: playerWon ? AtlasColors.green : AtlasColors.rust,
                    weight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  playerWon
                      ? 'Вы превзошли соперника в географической точности!'
                      : 'Соперник оказался точнее. Попробуйте ещё раз!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AtlasColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Rating Change Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AtlasColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ИЗМЕНЕНИЕ РЕЙТИНГА ELO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AtlasColors.muted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${player.rating}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AtlasColors.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            playerWon
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 20,
                            color: playerWon ? Colors.green : Colors.red,
                          ),
                          Text(
                            playerWon ? '+$ratingDiff' : '$ratingDiff',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: playerWon ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '→ ${player.rating + ratingDiff}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AtlasColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Раундов сыграно', value: '$totalRounds'),
                          _StatItem(
                            label: 'Остаток HP',
                            value: '${player.health} / 6000',
                          ),
                          _StatItem(
                            label: 'HP соперника',
                            value: '${opponent.health} / 6000',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                PrimaryButton(
                  label: 'НОВАЯ ДУЭЛЬ',
                  icon: Icons.replay,
                  accentColor: AtlasColors.green,
                  onPressed: onPlayAgain,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onGoHome,
                  child: const Text(
                    'Вернуться на главную',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AtlasColors.inkLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AtlasColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AtlasColors.muted,
          ),
        ),
      ],
    );
  }
}
