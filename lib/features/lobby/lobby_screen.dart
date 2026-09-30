import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/atlas_theme.dart';
import '../widgets/primary_button.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.onStartDuel,
    required this.playerRating,
    this.solid = false,
  });

  final VoidCallback onStartDuel;
  final int playerRating;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 680;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Eyebrow and Tagline
                    const Text(
                      'GEOGRAPHIC DUEL · СВЕТЛЫЙ АТЛАС',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: AtlasColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Узнайте мир.\nНа глаз.',
                      textAlign: TextAlign.center,
                      style: AtlasTheme.editorial(
                        isCompact ? 34 : 44,
                        color: AtlasColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Два игрока. Одна панорама. Ближайшая метка наносит урон.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AtlasColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Vector 3D Globe Illustration
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: isCompact ? 220 : 320,
                            maxWidth: isCompact ? 220 : 320,
                          ),
                          child: SvgPicture.asset(
                            'assets/globe.svg',
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AtlasColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: AtlasColors.gold),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Рейтинг: $playerRating Elo · Лига Исследователей',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AtlasColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Start Button
                    PrimaryButton(
                      label: 'Начать дуэль',
                      icon: Icons.play_arrow_rounded,
                      accentColor: AtlasColors.green,
                      onPressed: onStartDuel,
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      '5 раундов до победы · Настоящие координаты',
                      style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
