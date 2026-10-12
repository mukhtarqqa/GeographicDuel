import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Player Health Bar (Left)
          Expanded(
            child: _ModernPlayerHealthBox(
              player: player,
              isPlayer: true,
              solid: solid,
            ),
          ),

          const SizedBox(width: 8),

          // 2. Battle Hub (Round Pill, Multiplier & Circular Timer)
          _BattleCenterHub(
            roundNumber: roundNumber,
            multiplier: multiplier,
            remainingSeconds: remainingSeconds,
            isUrgent: isTimeUrgent,
            solid: solid,
          ),

          const SizedBox(width: 8),

          // 3. Opponent Health Bar (Right)
          Expanded(
            child: _ModernPlayerHealthBox(
              player: opponent,
              isPlayer: false,
              solid: solid,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleCenterHub extends StatelessWidget {
  const _BattleCenterHub({
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
        // Round badge with metallic sheen
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: multiplier > 1.0 ? const Color(0xfff59e0b) : Colors.white24,
              width: 1.2,
            ),
            boxShadow: [
              if (multiplier > 1.0)
                BoxShadow(
                  color: const Color(0xfff59e0b).withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Р$roundNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              if (multiplier > 1.0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xfff59e0b),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${multiplier.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Glowing Animated Timer Dial
        Semantics(
          label: '$remainingSeconds секунд қалды',
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: isUrgent ? 1.08 : 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: GlassContainer(
                  dark: true,
                  solid: solid,
                  radius: 30,
                  padding: EdgeInsets.zero,
                  borderColor: isUrgent
                      ? const Color(0xffef4444)
                      : Colors.white.withValues(alpha: 0.25),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isUrgent)
                          BoxShadow(
                            color: const Color(0xffef4444).withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: CircularProgressIndicator(
                            value: (remainingSeconds / 60.0).clamp(0.0, 1.0),
                            strokeWidth: 3.5,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUrgent ? const Color(0xffef4444) : const Color(0xff10b981),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$remainingSeconds',
                              style: TextStyle(
                                fontFamily: 'AtlasSerif',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isUrgent ? const Color(0xfff87171) : Colors.white,
                              ),
                            ),
                            const Text(
                              'СЕК',
                              style: TextStyle(
                                fontSize: 7,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModernPlayerHealthBox extends StatelessWidget {
  const _ModernPlayerHealthBox({
    required this.player,
    required this.isPlayer,
    required this.solid,
  });

  final PlayerState player;
  final bool isPlayer;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final health = player.health;
    final maxHealth = player.maxHealth;
    final healthPercent = (health / maxHealth).clamp(0.0, 1.0);
    final isCritical = healthPercent <= 0.25;

    // Gradient based on HP level
    final List<Color> gradientColors = isPlayer
        ? (isCritical
            ? [const Color(0xffef4444), const Color(0xfff87171)]
            : (healthPercent <= 0.5
                ? [const Color(0xfff59e0b), const Color(0xfffbbf24)]
                : [const Color(0xff059669), const Color(0xff34d399)]))
        : (isCritical
            ? [const Color(0xffef4444), const Color(0xfff87171)]
            : [const Color(0xffe11d48), const Color(0xfffb7185)]);

    final photoUrl = player.photoUrl;

    return GlassContainer(
      dark: true,
      solid: solid,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderColor: isCritical
          ? const Color(0xffef4444).withValues(alpha: 0.8)
          : (isPlayer
              ? const Color(0xff10b981).withValues(alpha: 0.3)
              : const Color(0xfff43f5e).withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment:
            isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player identity row
          Row(
            mainAxisAlignment:
                isPlayer ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isPlayer) ...[
                _buildAvatar(photoUrl, player.name, isPlayer),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      isPlayer ? 'Сіз · ${player.rating} Elo' : 'Қарсылас · ${player.rating} Elo',
                      style: TextStyle(
                        fontSize: 9,
                        color: isPlayer ? const Color(0xffa7f3d0) : const Color(0xfffecdd3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPlayer) ...[
                const SizedBox(width: 8),
                _buildAvatar(photoUrl, player.name, isPlayer),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Numeric HP readout with heart icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 11,
                    color: isCritical ? const Color(0xffef4444) : gradientColors.first,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${(healthPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCritical ? const Color(0xfff87171) : Colors.white70,
                    ),
                  ),
                ],
              ),
              Text(
                '$health HP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isCritical ? const Color(0xfff87171) : Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Thick glowing animated Health Bar (10px height with bevel)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12, width: 0.8),
              ),
              alignment: isPlayer ? Alignment.centerLeft : Alignment.centerRight,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                widthFactor: healthPercent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.last.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
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

  Widget _buildAvatar(String? photoUrl, String name, bool isUser) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser ? const Color(0xff10b981) : const Color(0xfff43f5e),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 13,
        backgroundColor: isUser ? const Color(0xff065f46) : const Color(0xff881337),
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : (isUser ? 'С' : 'Қ'),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

