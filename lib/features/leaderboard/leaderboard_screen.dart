import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../services/auth_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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
                  '01 МЕЗГІЛ · ДҮНИЕЖҮЗІЛІК ЕСЕП',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AtlasColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Көшбасшылар кестесі',
                  style: AtlasTheme.editorial(32),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<UserProfile>>(
              future: UserRepository.instance.getLeaderboard(limit: 20),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AtlasColors.ink));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Қате: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                final players = snapshot.data ?? [];

                if (players.isEmpty) {
                  return const Center(child: Text('Деректер жоқ'));
                }

                final currentUserId = AuthService.instance.currentUser?.uid;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = players[index];
                    final isSelf = item.uid == currentUserId;
                    final rank = index + 1;

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
                              '#$rank',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: rank <= 3 ? AtlasColors.gold : AtlasColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelf ? AtlasColors.green : AtlasColors.paperDark,
                            child: Text(
                              item.displayName.isNotEmpty ? item.displayName.substring(0, 1).toUpperCase() : '?',
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
                                  item.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelf ? FontWeight.bold : FontWeight.w600,
                                    color: AtlasColors.ink,
                                  ),
                                ),
                                Text(
                                  '${item.matchesWon} жеңіс · Жер',
                                  style: const TextStyle(fontSize: 11, color: AtlasColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.eloRating} Elo',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
