import 'package:flutter/material.dart';
import '../../../core/theme/atlas_theme.dart';
import '../../widgets/glass_container.dart';
import '../../../domain/models/player_state.dart';

class DuelTopHud extends StatelessWidget {
  const DuelTopHud({
    super.key,
    required this.player,
    required this.opponent,
    required this.roundNumber,
    required this.multiplier,
    required this.remainingSeconds,
    this.solid = false,
  });

  final PlayerState player;
  final PlayerState opponent;
  final int roundNumber;
  final double multiplier;
  final int remainingSeconds;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final isTimeUrgent = remainingSeconds <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Player 1 Health Bar
              Expanded(
                child: _PlayerHealthBox(
                  name: player.name,
                  health: player.health,
                  maxHealth: player.maxHealth,
                  barColor: const Color(0xff4ade80), // Vibrant Green
                  isPlayer: true,
                  solid: solid,
                ),
              ),

              const SizedBox(width: 10),

              // Center Round & Timer Dial
              _CenterTimerDial(
                roundNumber: roundNumber,
                multiplier: multiplier,
                remainingSeconds: remainingSeconds,
                isUrgent: isTimeUrgent,
                solid: solid,
              ),

              const SizedBox(width: 10),

              // Opponent Health Bar
              Expanded(
                child: _PlayerHealthBox(
                  name: opponent.name,
                  health: opponent.health,
                  maxHealth: opponent.maxHealth,
                  barColor: const Color(0xfff87171), // Coral / Rust
                  isPlayer: false,
                  solid: solid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterTimerDial extends StatelessWidget {
  const _CenterTimerDial({
    required this.roundNumber,
    required this.multiplier,
    required this.remainingSeconds,
    required this.isUrgent,
    required this.solid,
  });

  final int roundNumber;
  final double multiplier;
  final int remainingSeconds;
  final bool isUrgent;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Round & Multiplier Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: multiplier > 1.0
                  ? AtlasColors.gold.withValues(alpha: 0.8)
                  : Colors.white24,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'R$roundNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (multiplier > 1.0) ...[
                const SizedBox(width: 4),
                Text(
                  '${multiplier.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: AtlasColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 5),

        // Glowing Timer Circle
        Semantics(
          label: 'Осталось $remainingSeconds секунд',
          child: GlassContainer(
            dark: true,
            solid: solid,
            radius: 36,
            padding: EdgeInsets.zero,
            borderColor: isUrgent ? const Color(0xffff4d4f) : null,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: remainingSeconds / 60.0,
                    strokeWidth: 3,
                    backgroundColor: Colors.white12,
                    color: isUrgent
                        ? const Color(0xffff4d4f)
                        : const Color(0xffe9ef9c),
                  ),
                  Text(
                    '$remainingSeconds',
                    style: TextStyle(
                      fontFamily: 'AtlasSerif',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: isUrgent ? const Color(0xffff6b6b) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerHealthBox extends StatelessWidget {
  const _PlayerHealthBox({
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.barColor,
    required this.isPlayer,
    required this.solid,
  });

  final String name;
  final int health;
  final int maxHealth;
  final Color barColor;
  final bool isPlayer;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final healthPercent = (health / maxHealth).clamp(0.0, 1.0);

    return GlassContainer(
      dark: true,
      solid: solid,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment:
            isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment:
                isPlayer ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isPlayer) ...[
                CircleAvatar(
                  radius: 9,
                  backgroundColor: AtlasColors.green,
                  child: const Text(
                    'Я',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isPlayer) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 9,
                  backgroundColor: AtlasColors.rust,
                  child: const Text(
                    'С',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPlayer ? 'HP' : '',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
              Text(
                '$health',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: healthPercent < 0.25 ? const Color(0xffff6b6b) : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Animated Health Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 5,
              width: double.infinity,
              color: Colors.black38,
              alignment: isPlayer ? Alignment.centerLeft : Alignment.centerRight,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                widthFactor: healthPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
