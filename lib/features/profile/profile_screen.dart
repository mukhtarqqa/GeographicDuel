import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/player_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.player,
    required this.solid,
    required this.reduceMotion,
    required this.onToggleSolid,
    required this.onToggleReduceMotion,
  });

  final PlayerState player;
  final bool solid;
  final bool reduceMotion;
  final ValueChanged<bool> onToggleSolid;
  final ValueChanged<bool> onToggleReduceMotion;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const Text(
            'ПРОФИЛЬ ИССЛЕДОВАТЕЛЯ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: AtlasColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Настройки и статистика',
            style: AtlasTheme.editorial(30),
          ),
          const SizedBox(height: 20),

          // User Card
          Container(
            padding: const EdgeInsets.all(18),
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AtlasColors.green,
                  child: const Text(
                    'М',
                    style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AtlasColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Рейтинг: ${player.rating} Elo · Золотая лига',
                        style: const TextStyle(fontSize: 12, color: AtlasColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accessibility & Display Settings
          const Text(
            'ДОСТУПНОСТЬ И ОФОРМЛЕНИЕ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: AtlasColors.muted,
            ),
          ),
          const SizedBox(height: 8),

          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AtlasColors.line),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Уменьшить прозрачность (Solid Glass)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AtlasColors.ink),
                    ),
                    subtitle: const Text(
                      'Заменяет размытие фона на плотную матовую подложку для повышения контраста',
                      style: TextStyle(fontSize: 12, color: AtlasColors.muted),
                    ),
                    value: solid,
                    activeTrackColor: AtlasColors.green,
                    onChanged: onToggleSolid,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Уменьшить движение (Reduce Motion)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AtlasColors.ink),
                    ),
                    subtitle: const Text(
                      'Отключает плавные переходы между экранами и анимации карты',
                      style: TextStyle(fontSize: 12, color: AtlasColors.muted),
                    ),
                    value: reduceMotion,
                    activeTrackColor: AtlasColors.green,
                    onChanged: onToggleReduceMotion,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About app
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AtlasColors.paperDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geographic Duel · v0.2.0',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AtlasColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  'Геометрия Natural Earth (d3-geo). Светлый атлас. Android, iOS и Web.',
                  style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
