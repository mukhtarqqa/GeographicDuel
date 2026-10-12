import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/round_result.dart';
import '../../domain/models/player_state.dart';
import '../../atlas_map.dart';
import '../widgets/primary_button.dart';
import 'widgets/score_card.dart';
import 'widgets/health_overview.dart';
import 'widgets/damage_banner.dart';

class RoundResultScreen extends StatefulWidget {
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

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {
  bool _waitingOpponent = false;

  bool get isMatchOver =>
      widget.player.health <= 0 ||
      widget.opponent.health <= 0 ||
      widget.result.roundNumber >= 10;

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
                'РАУНД 0${widget.result.roundNumber} · НӘТИЖЕСІ',
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
                widget.result.summaryTitle,
                textAlign: TextAlign.center,
                style: AtlasTheme.editorial(28),
              ),
              const SizedBox(height: 4),

              // Actual Location details
              Text(
                '${widget.result.location.title} · ${widget.result.location.country}',
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
                        selected: widget.result.playerGuess,
                        target: widget.result.location.coordinates,
                        opponent: widget.result.opponentGuess,
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
                              _LegendDot(color: Color(0xff52c41a), label: 'Дұрыс орын'),
                              SizedBox(width: 8),
                              _LegendDot(color: AtlasColors.green, label: 'Сіз'),
                              SizedBox(width: 8),
                              _LegendDot(color: AtlasColors.rust, label: 'Қарсылас'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Score Breakdown Cards
              Row(
                children: [
                  Expanded(
                    child: ScoreCard(
                      playerName: widget.player.name,
                      distanceKm: widget.result.playerDistanceKm,
                      score: widget.result.playerScore,
                      isWinner: widget.result.playerWon,
                      color: AtlasColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScoreCard(
                      playerName: widget.opponent.name,
                      distanceKm: widget.result.opponentDistanceKm,
                      score: widget.result.opponentScore,
                      isWinner: widget.result.opponentWon,
                      color: AtlasColors.rust,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Damage & Multiplier Banner
              DamageBanner(result: widget.result),
              const SizedBox(height: 18),

              // Updated Health Bars Status
              HealthOverview(
                playerName: widget.player.name,
                playerHealth: widget.player.health,
                opponentName: widget.opponent.name,
                opponentHealth: widget.opponent.health,
              ),
              const SizedBox(height: 24),

              // Main CTA Button
              PrimaryButton(
                label: isMatchOver
                    ? 'МАТЧТЫ ҚОРЫТЫНДЫЛАУ'
                    : (_waitingOpponent
                        ? 'Қарсыласты күтудеміз...'
                        : 'КЕЛЕСІ РАУНД (${widget.result.roundNumber + 1})'),
                icon: isMatchOver
                    ? Icons.emoji_events_outlined
                    : (_waitingOpponent ? Icons.hourglass_top : Icons.arrow_forward),
                accentColor: isMatchOver
                    ? AtlasColors.rust
                    : (_waitingOpponent ? AtlasColors.muted : AtlasColors.green),
                onPressed: _waitingOpponent
                    ? null
                    : () {
                        if (isMatchOver) {
                          widget.onFinishMatch();
                        } else {
                          setState(() => _waitingOpponent = true);
                          widget.onNextRound();
                        }
                      },
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
