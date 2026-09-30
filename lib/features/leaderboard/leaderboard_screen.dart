import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const List<Map<String, dynamic>> _topPlayers = [
    {'rank': 1, 'name': 'GeoMaster_KZ', 'rating': 2480, 'country': 'KZ', 'wins': 142},
    {'rank': 2, 'name': 'AtlasWalker', 'rating': 2390, 'country': 'FR', 'wins': 118},
    {'rank': 3, 'name': 'Sofia_Wanderer', 'rating': 2250, 'country': 'IT', 'wins': 95},
    {'rank': 4, 'name': 'CompassKing', 'rating': 2110, 'country': 'JP', 'wins': 84},
    {'rank': 5, 'name': 'Алина (Сеул)', 'rating': 1980, 'country': 'KR', 'wins': 76},
    {'rank': 6, 'name': 'Вы (Исследователь)', 'rating': 1240, 'country': 'KZ', 'wins': 12, 'isSelf': true},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'СЕЗОН 01 · МИРОВОЙ ЗАЧЁТ',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AtlasColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Таблица лидеров',
                  style: AtlasTheme.editorial(32),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _topPlayers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _topPlayers[index];
                final isSelf = item['isSelf'] == true;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelf ? const Color(0xffe8f3ee) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelf ? AtlasColors.green : AtlasColors.line,
                      width: isSelf ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        alignment: Alignment.center,
                        child: Text(
                          '#${item['rank']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item['rank'] <= 3 ? AtlasColors.gold : AtlasColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isSelf ? AtlasColors.green : AtlasColors.paperDark,
                        child: Text(
                          (item['name'] as String).substring(0, 1),
                          style: TextStyle(
                            color: isSelf ? Colors.white : AtlasColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelf ? FontWeight.bold : FontWeight.w600,
                                color: AtlasColors.ink,
                              ),
                            ),
                            Text(
                              '${item['wins']} побед · ${item['country']}',
                              style: const TextStyle(fontSize: 11, color: AtlasColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item['rating']} Elo',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AtlasColors.ink,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
