import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/atlas_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_logo.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.onStartDuel,
    required this.playerRating,
    this.onCreateRoom,
    this.onJoinRoom,
    this.onLogout,
    this.solid = false,
  });

  final VoidCallback onStartDuel;
  final int playerRating;
  final VoidCallback? onCreateRoom;
  final ValueChanged<String>? onJoinRoom;
  final VoidCallback? onLogout;
  final bool solid;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtlasColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AtlasColors.rust, size: 22),
            SizedBox(width: 8),
            Text('Жүйеден шығу', style: TextStyle(fontWeight: FontWeight.bold, color: AtlasColors.ink)),
          ],
        ),
        content: const Text(
          'Шынымен аккаунтыңыздан шыққыңыз келе ме? Қайта кіру үшін авторизация қажет болады.',
          style: TextStyle(fontSize: 14, color: AtlasColors.inkLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Болдырмау', style: TextStyle(color: AtlasColors.muted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.rust,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout?.call();
            },
            child: const Text('Иә, шығу', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCustomRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtlasColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Доспен ойнау',
          style: TextStyle(color: AtlasColors.ink, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Бөлме жасаңыз немесе досыңыздың 6 таңбалы кодын енгізіңіз:',
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
              label: const Text('Жаңа бөлме құру', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: Text('НЕМЕСЕ', style: TextStyle(fontSize: 11, color: AtlasColors.muted)),
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
              child: const Text('Код арқылы кіру', style: TextStyle(fontWeight: FontWeight.bold)),
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
        color: const Color(0xffd97706).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffd97706).withValues(alpha: 0.3)),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 12, color: Color(0xffd97706)),
            SizedBox(width: 5),
            Text(
              'Firebase Firestore',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xffd97706),
              ),
            ),
          ],
        ),
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
            // Extra bottom padding (100px) so buttons NEVER overlap with the bottom navigation dock
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 116).clamp(0.0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top Bar with Logo, Eyebrow and visible "Шығу" (Logout) button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const AppLogo(size: 38),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'GEOGRAPHIC DUEL',
                                        style: TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.bold,
                                          color: AtlasColors.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    _buildBackendBadge(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Prominent Logout button right on the main screen
                        Semantics(
                          button: true,
                          label: 'Жүйеден шығу',
                          child: InkWell(
                            onTap: () => _showLogoutDialog(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xfffff1f0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xffffccc7), width: 1.2),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout_rounded, size: 15, color: Color(0xffcf1322)),
                                  SizedBox(width: 5),
                                  Text(
                                    'Шығу',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffcf1322),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Әлемді таны.\nКөзбен.',
                      textAlign: TextAlign.center,
                      style: AtlasTheme.editorial(
                        isCompact ? 30 : 38,
                        color: AtlasColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),

                    const Text(
                      'Екі ойыншы. Бір панорама. Ең жақын белгі зақым келтіреді.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AtlasColors.muted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Vector 3D Globe Illustration
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: isCompact ? 160 : 230,
                            maxWidth: isCompact ? 160 : 230,
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
                    const SizedBox(height: 14),

                    // Quick Stats Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          Text(
                            'Рейтинг: ${widget.playerRating} Elo',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AtlasColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Start Button (full-width container to prevent collisions)
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Жылдам жекпе-жек',
                        icon: Icons.play_arrow_rounded,
                        accentColor: AtlasColors.green,
                        onPressed: widget.onStartDuel,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Play With Friend Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AtlasColors.ink,
                          side: const BorderSide(color: AtlasColors.line, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.people_alt_outlined, size: 18),
                        label: const Text(
                          'Код арқылы доспен ойнау',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _showCustomRoomDialog(context),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      '10 раундқа дейін · Нақты координаттар',
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
