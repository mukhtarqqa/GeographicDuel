import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Radar / Pulse Rings
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) {
                    return SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRing(1.0 - _anim.value, 180),
                          _buildRing((0.7 - _anim.value).abs(), 130),
                          _buildRing((0.4 - _anim.value).abs(), 80),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: AtlasColors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x55315e4c),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.explore,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                const Text(
                  'Мир на двоих.',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AtlasColors.muted,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Ищем достойного соперника...',
                  textAlign: TextAlign.center,
                  style: AtlasTheme.editorial(28),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Подбор по рейтингу Elo и географическому региону',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AtlasColors.muted,
                  ),
                ),
                const SizedBox(height: 48),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AtlasColors.line),
                    foregroundColor: AtlasColors.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Отменить поиск'),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRing(double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AtlasColors.green.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.45),
          width: 1.5,
        ),
      ),
    );
  }
}
