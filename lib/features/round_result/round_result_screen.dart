import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/round_result.dart';
import '../../domain/models/player_state.dart';
import '../../atlas_map.dart';
import '../widgets/primary_button.dart';

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

  String _formatNumber(num n) {
    final str = n.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

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
                    child: _ScoreCard(
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
                    child: _ScoreCard(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: result.isTie
                      ? const Color(0xfff0f2ee)
                      : (result.playerWon
                          ? const Color(0xfff6ffed)
                          : const Color(0xfffff1f0)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: result.isTie
                        ? AtlasColors.line
                        : (result.playerWon
                            ? const Color(0xffb7eb8f)
                            : const Color(0xffffccc7)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            result.isTie
                                ? 'Урона нет (ничья)'
                                : (result.playerWon
                                    ? 'Урон сопернику:'
                                    : 'Полученный урон:'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: result.playerWon
                                  ? const Color(0xff389e0d)
                                  : const Color(0xffcf1322),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.damage == 0 ? '0 HP' : '−${_formatNumber(result.damage)} HP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: result.playerWon
                                ? const Color(0xff389e0d)
                                : const Color(0xffcf1322),
                          ),
                        ),
                      ],
                    ),
                    if (result.multiplier > 1.0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AtlasColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Множитель урона: ${result.multiplier.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff996600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Updated Health Bars Status
              _HealthOverview(
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

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
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

class _HealthOverview extends StatelessWidget {
  const _HealthOverview({
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
