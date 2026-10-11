import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/atlas_theme.dart';
import '../../data/firebase/firebase_duel_service.dart';
import '../widgets/primary_button.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.onStartDuel,
    required this.playerRating,
    this.onCreateRoom,
    this.onJoinRoom,
    this.solid = false,
  });

  final VoidCallback onStartDuel;
  final int playerRating;
  final VoidCallback? onCreateRoom;
  final ValueChanged<String>? onJoinRoom;
  final bool solid;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _showCustomRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtlasColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Доспен ойнау', // Игра с другом
          style: TextStyle(color: AtlasColors.ink, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Бөлме жасаңыз немесе досыңыздың 6 таңбалы кодын енгізіңіз:', // Создайте комнату или...
              style: TextStyle(fontSize: 13, color: AtlasColors.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AtlasColors.paperDark,
                foregroundColor: AtlasColors.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Жаңа бөлме құру', style: TextStyle(fontWeight: FontWeight.bold)), // Создать новую комнату
              onPressed: () {
                Navigator.pop(ctx);
                widget.onCreateRoom?.call();
              },
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('НЕМЕСЕ', style: TextStyle(fontSize: 11, color: AtlasColors.muted)), // ИЛИ
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AtlasColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AtlasColors.green, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AtlasColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(ctx);
                  widget.onJoinRoom?.call(code);
                }
              },
              child: const Text('Код арқылы кіру', style: TextStyle(fontWeight: FontWeight.bold)), // Войти по коду
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AtlasColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AtlasColors.green.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 12, color: AtlasColors.green),
          SizedBox(width: 5),
          Text(
            'Firebase Cloud Firestore',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AtlasColors.green,
            ),
          ),
        ],
      ),
    );
  }

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
                      'GEOGRAPHIC DUEL · ЖАРЫҚ АТЛАС', // СВЕТЛЫЙ АТЛАС
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: AtlasColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Backend Status Badge
                    _buildBackendBadge(),
                    const SizedBox(height: 10),

                    Text(
                      'Әлемді таны.\nКөзбен.', // Узнайте мир. На глаз.
                      textAlign: TextAlign.center,
                      style: AtlasTheme.editorial(
                        isCompact ? 32 : 40,
                        color: AtlasColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),

                    const Text(
                      'Екі ойыншы. Бір панорама. Ең жақын белгі зақым келтіреді.', // Два игрока. Одна панорама...
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AtlasColors.muted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vector 3D Globe Illustration
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: isCompact ? 180 : 260,
                            maxWidth: isCompact ? 180 : 260,
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
                    const SizedBox(height: 16),

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
                              'Рейтинг: ${widget.playerRating} Elo · Зерттеушілер лигасы', // Лига Исследователей
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
                    const SizedBox(height: 14),

                    // Main Start Button
                    PrimaryButton(
                      label: 'Жылдам жекпе-жек', // Быстрая дуэль
                      icon: Icons.play_arrow_rounded,
                      accentColor: AtlasColors.green,
                      onPressed: widget.onStartDuel,
                    ),
                    const SizedBox(height: 8),

                    // Play With Friend Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AtlasColors.ink,
                        side: const BorderSide(color: AtlasColors.line, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      label: const Text('Код арқылы доспен ойнау', style: TextStyle(fontWeight: FontWeight.w600)), // Играть с другом по коду
                      onPressed: () => _showCustomRoomDialog(context),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Жеңіске дейін 5 раунд · Нақты координаттар', // 5 раундов до победы
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
