import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xff141d1a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Color(0xff34d399)),
              SizedBox(width: 6),
              Text(
                'ЖЕКПЕ-ЖЕК ДЕНСАУЛЫҒЫ (HP)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xff94a3b8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Player and Opponent Bars
          Row(
            children: [
              Expanded(
                child: _PlayerHpCard(
                  name: playerName,
                  health: playerHealth,
                  isPlayer: true,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff64748b),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: _PlayerHpCard(
                  name: opponentName,
                  health: opponentHealth,
                  isPlayer: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerHpCard extends StatelessWidget {
  const _PlayerHpCard({
    required this.name,
    required this.health,
    required this.isPlayer,
  });

  final String name;
  final int health;
  final bool isPlayer;

  @override
  Widget build(BuildContext context) {
    final clampedHp = health.clamp(0, 6000);
    final ratio = clampedHp / 6000.0;
    final isCritical = ratio <= 0.25;

    final primaryColor = isPlayer
        ? (ratio > 0.45 ? const Color(0xff10b981) : (ratio > 0.2 ? const Color(0xfff59e0b) : const Color(0xffef4444)))
        : (ratio > 0.45 ? const Color(0xffef4444) : (ratio > 0.2 ? const Color(0xfff97316) : const Color(0xffb91c1c)));

    return Column(
      crossAxisAlignment: isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Name & Tag
        Row(
          mainAxisAlignment: isPlayer ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isPlayer) const Icon(Icons.favorite, size: 12, color: Color(0xff10b981)),
            if (isPlayer) const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPlayer ? const Color(0xff34d399) : const Color(0xfff87171),
                ),
              ),
            ),
            if (!isPlayer) const SizedBox(width: 4),
            if (!isPlayer) const Icon(Icons.flash_on, size: 12, color: Color(0xffef4444)),
          ],
        ),
        const SizedBox(height: 4),

        // HP Value
        Row(
          mainAxisAlignment: isPlayer ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            Text(
              '$clampedHp',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            const Text(
              ' / 6000',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xff64748b),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // HP Bar
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Align(
              alignment: isPlayer ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.75),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: isCritical ? 0.8 : 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
