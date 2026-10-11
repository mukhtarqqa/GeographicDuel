import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/round_result.dart';
import '../../domain/models/player_state.dart';
import '../../atlas_map.dart';
import '../widgets/primary_button.dart';
import 'widgets/score_card.dart';
import 'widgets/health_overview.dart';
import 'widgets/damage_banner.dart';

class RoundResultScreen extends StatelessWidget {
  const RoundResultScreen({
    super.key,
    required this.result,
    required this.player,
    required this.opponent,
    required this.onNextRound,
    required this.onFinishMatch,
    this.solid = false,
  });

  final DuelRoundResult result;
  final PlayerState player;
  final PlayerState opponent;
  final VoidCallback onNextRound;
  final VoidCallback onFinishMatch;
  final bool solid;

  bool get isMatchOver => player.health <= 0 || opponent.health <= 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Round Eyebrow
              Text(
                'РАУНД 0${result.roundNumber} · РЕЗУЛЬТАТ',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                  color: AtlasColors.muted,
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                result.summaryTitle,
                textAlign: TextAlign.center,
                style: AtlasTheme.editorial(28),
              ),
              const SizedBox(height: 4),

              // Actual Location details
              Text(
                '${result.location.title} · ${result.location.country}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AtlasColors.inkLight,
                ),
              ),
              const SizedBox(height: 16),

              // Map with Target, Player and Opponent pins
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AtlasColors.mapWater,
                    border: Border.all(color: AtlasColors.line),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      AtlasMap(
                        selected: result.playerGuess,
                        target: result.location.coordinates,
                        opponent: result.opponentGuess,
                      ),
                      // Legend pill
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LegendDot(color: AtlasColors.green, label: 'Вы'),
                              SizedBox(width: 8),
                              _LegendDot(color: AtlasColors.rust, label: 'Соперник'),
                              SizedBox(width: 8),
                              _LegendDot(color: AtlasColors.gold, label: 'Цель'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scores Comparison Grid
              Row(
                children: [
                  Expanded(
                    child: ScoreCard(
                      playerName: player.name,
                      distanceKm: result.playerDistance,
                      score: result.playerScore,
                      isWinner: result.playerWon,
                      color: AtlasColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AtlasColors.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScoreCard(
                      playerName: opponent.name,
                      distanceKm: result.opponentDistance,
                      score: result.opponentScore,
                      isWinner: result.opponentWon,
                      color: AtlasColors.rust,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Damage & Multiplier Banner
              DamageBanner(result: result),
              const SizedBox(height: 18),

              // Updated Health Bars Status
              HealthOverview(
                playerName: player.name,
                playerHealth: player.health,
                opponentName: opponent.name,
                opponentHealth: opponent.health,
              ),
              const SizedBox(height: 24),

              // Main CTA Button
              PrimaryButton(
                label: isMatchOver
                    ? 'ПОДВЕСТИ ИТОГИ МАТЧА'
                    : 'СЛЕДУЮЩИЙ РАУНД (${result.roundNumber + 1})',
                icon: Icons.arrow_forward,
                accentColor: isMatchOver ? AtlasColors.rust : AtlasColors.green,
                onPressed: isMatchOver ? onFinishMatch : onNextRound,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AtlasColors.ink),
        ),
      ],
    );
  }
}
