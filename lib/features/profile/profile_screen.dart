import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/player_state.dart';
import '../../services/auth_service.dart';
import '../../data/repositories/user_repository.dart';
import '../widgets/app_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.player,
    required this.solid,
    required this.reduceMotion,
    required this.onToggleSolid,
    required this.onToggleReduceMotion,
    this.onLogout,
    this.onUserUpdated,
  });

  final PlayerState player;
  final bool solid;
  final bool reduceMotion;
  final ValueChanged<bool> onToggleSolid;
  final ValueChanged<bool> onToggleReduceMotion;
  final VoidCallback? onLogout;
  final VoidCallback? onUserUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSwitching = false;

  void _showEditProfileModal(BuildContext context) {
    final nameController = TextEditingController(text: widget.player.name);
    final authUser = AuthService.instance.currentUser;
    String currentAvatar = widget.player.photoUrl ?? authUser?.photoURL ?? '';
    final urlController = TextEditingController(text: currentAvatar);
    bool isSaving = false;

    final avatarPresets = [
      {'name': 'Түлкі', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=FoxAtlas&backgroundColor=b6e3f4'},
      {'name': 'Қыран', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=EagleKaz&backgroundColor=c0aede'},
      {'name': 'Бөрі', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=WolfSteppe&backgroundColor=d1d4f9'},
      {'name': 'Саяхатшы', 'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=TravelerQaz&backgroundColor=ffd5dc'},
      {'name': 'Ғарышкер', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=CosmoGeo&backgroundColor=ffdfbf'},
      {'name': 'Зерттеуші', 'url': 'https://api.dicebear.com/7.x/bottts/png?seed=ExplorerNomad&backgroundColor=d1f4d9'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AtlasColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, color: AtlasColors.green, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Профильді өңдеу',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AtlasColors.ink),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Лақап атыңызды жазыңыз және өзіңізге ұнайтын аватарды таңдаңыз:',
                    style: TextStyle(fontSize: 13, color: AtlasColors.muted),
                  ),
                  const SizedBox(height: 18),

                  // Avatar Preview & Presets
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AtlasColors.green,
                          backgroundImage: (currentAvatar.isNotEmpty)
                              ? NetworkImage(currentAvatar)
                              : null,
                          child: (currentAvatar.isEmpty)
                              ? Text(
                                  nameController.text.isNotEmpty
                                      ? nameController.text.substring(0, 1).toUpperCase()
                                      : 'З',
                                  style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        if (currentAvatar.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  currentAvatar = '';
                                  urlController.text = '';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'ДАЙЫН АВАТАРЛАР (ТАҢДАУ):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AtlasColors.muted),
                  ),
                  const SizedBox(height: 8),

                  // Presets Row
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: avatarPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final p = avatarPresets[i];
                        final isSelected = currentAvatar == p['url'];
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              currentAvatar = p['url']!;
                              urlController.text = p['url']!;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AtlasColors.green : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(p['url']!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Display Name input
                  TextField(
                    controller: nameController,
                    maxLength: 25,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Ойыншының есімі / Лақап ат',
                      hintText: 'Мысалы: Жас Зерттеуші',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AtlasColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AtlasColors.green, width: 2),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Custom URL input
                  TextField(
                    controller: urlController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Өз фотоңыздың URL сілтемесі (қалауыңызша)',
                      hintText: 'https://mysite.kz/photo.png',
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AtlasColors.line),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        currentAvatar = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AtlasColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newName = nameController.text.trim();
                            if (newName.isEmpty) return;

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);

                            setModalState(() => isSaving = true);
                            final user = AuthService.instance.currentUser;
                            if (user != null) {
                              await AuthService.instance.updateDisplayName(newName);
                              await UserRepository.instance.updateDisplayName(user.uid, newName);
                              if (currentAvatar.isNotEmpty) {
                                await AuthService.instance.updatePhotoUrl(currentAvatar);
                                await UserRepository.instance.updatePhotoUrl(user.uid, currentAvatar);
                              }
                            }
                            widget.onUserUpdated?.call();

                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Профиль мен аватар сәтті жаңартылды!'),
                                backgroundColor: AtlasColors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Сақтау',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtlasColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AtlasColors.rust, size: 24),
            SizedBox(width: 10),
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

  Future<void> _switchWithGoogle() async {
    setState(() => _isSwitching = true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential?.user != null && mounted) {
        widget.onUserUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google аккаунты сәтті ауыстырылды!'),
            backgroundColor: AtlasColors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getKazakhErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitching = false);
      }
    }
  }

  void _showSwitchAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AtlasColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.switch_account_rounded, color: AtlasColors.green, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Аккаунтты ауыстыру',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AtlasColors.ink),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Басқа Google профилін таңдаңыз немесе авторизация экранына өтіңіз:',
              style: TextStyle(fontSize: 13, color: AtlasColors.muted),
            ),
            const SizedBox(height: 18),

            // Google Account Switch Option
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(ctx);
                  _switchWithGoogle();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AtlasColors.line),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, color: Color(0xff4285F4)),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google арқылы ауыстыру',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AtlasColors.ink),
                            ),
                            Text(
                              'Басқа Google поштасын таңдау (1-басу)',
                              style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AtlasColors.muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Other Login Screen Option
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onLogout?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AtlasColors.line),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.login_rounded, color: AtlasColors.ink, size: 22),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Кіру экранына қайту',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AtlasColors.ink),
                            ),
                            Text(
                              'Қазіргі сессиядан шығып, авторизация терезесін ашу',
                              style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AtlasColors.muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = AuthService.instance.currentUser;
    final userEmail = authUser?.email;
    final photoUrl = widget.player.photoUrl ?? authUser?.photoURL;
    final isGoogleUser = authUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final isAnonymous = authUser?.isAnonymous ?? true;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Header with App Logo and Logout button
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
                                color: AtlasColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Жеке профиль',
                              style: AtlasTheme.editorial(22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff1f0),
                    borderRadius: BorderRadius.circular(12),
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
            ],
          ),
          const SizedBox(height: 18),

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showEditProfileModal(context),
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AtlasColors.green,
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Text(
                                    widget.player.name.isNotEmpty
                                        ? widget.player.name.substring(0, 1).toUpperCase()
                                        : 'З',
                                    style: const TextStyle(
                                        fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AtlasColors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.player.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AtlasColors.ink,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _showEditProfileModal(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AtlasColors.paperDark,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AtlasColors.line),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined, size: 13, color: AtlasColors.ink),
                                      SizedBox(width: 4),
                                      Text(
                                        'Өңдеу',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AtlasColors.ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (userEmail != null && userEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 12, color: AtlasColors.muted),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Рейтинг: ${widget.player.rating} Elo · Зерттеушілер лигасы',
                            style: const TextStyle(
                                fontSize: 12, color: AtlasColors.muted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Account Type Badge
                Row(
                  children: [
                    if (isGoogleUser) ...[
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => const Icon(Icons.check_circle, size: 16, color: Color(0xff4285F4)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Google аккаунтымен қосылған',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff1a73e8)),
                      ),
                    ] else if (isAnonymous) ...[
                      const Icon(Icons.person_pin_outlined, size: 16, color: Color(0xffd48806)),
                      const SizedBox(width: 8),
                      const Text(
                        'Қонақ аккаунты (уақытша сессия)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xffd48806)),
                      ),
                    ] else ...[
                      const Icon(Icons.mail_outline_rounded, size: 16, color: AtlasColors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Электрондық поштамен кірген',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AtlasColors.green),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // If Guest: Prompt to connect Google
          if (isAnonymous) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfffffbe6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffffe58f)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xffd48806), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Рейтингті сақтау үшін',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xffd48806)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Сіз қонақ режиміндесіз. Ұпайлар мен жеңістер сақталуы үшін Google арқылы кіріңіз.',
                    style: TextStyle(fontSize: 12, color: AtlasColors.inkLight),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AtlasColors.ink,
                      elevation: 0,
                      side: const BorderSide(color: AtlasColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 18, color: Color(0xff4285F4)),
                    ),
                    label: const Text(
                      'Google аккаунтына ауысу',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSwitching ? null : _switchWithGoogle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Edit Profile Action Tile (Профильді өңдеу)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showEditProfileModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AtlasColors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.badge_outlined, color: AtlasColors.green, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Профильді өңдеу',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AtlasColors.green,
                            ),
                          ),
                          Text(
                            'Ойыншы есімін немесе лақап атын өзгерту',
                            style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AtlasColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Account Switch Action Tile (Басқа аккаунтқа ауыстыру)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _isSwitching ? null : () => _showSwitchAccountModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xff1a73e8).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.switch_account_rounded, color: Color(0xff1a73e8), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Аккаунтты ауыстыру',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1a73e8),
                            ),
                          ),
                          Text(
                            _isSwitching
                                ? 'Google терезесі ашылуда...'
                                : 'Басқа Google немесе пошта аккаунтына ауысу',
                            style: const TextStyle(fontSize: 11, color: AtlasColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (_isSwitching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AtlasColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Logout Action (Placed immediately below user card so it is 100% visible)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showLogoutDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AtlasColors.rust.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AtlasColors.rust, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Жүйеден шығу',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AtlasColors.rust,
                            ),
                          ),
                          Text(
                            'Сессияны аяқтау және авторизация экранына қайту',
                            style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AtlasColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Accessibility & Display Settings
          const Text(
            'ҚОЛЖЕТІМДІЛІК ЖӘНЕ РЕСІМДЕУ',
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
                      'Мөлдірлікті азайту (Solid Glass)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AtlasColors.ink),
                    ),
                    subtitle: const Text(
                      'Контрастты арттыру үшін фонды бұлыңғырлауды тығыз маталы негізге ауыстырады',
                      style: TextStyle(fontSize: 12, color: AtlasColors.muted),
                    ),
                    value: widget.solid,
                    activeTrackColor: AtlasColors.green,
                    onChanged: widget.onToggleSolid,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Қозғалысты азайту (Reduce Motion)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AtlasColors.ink),
                    ),
                    subtitle: const Text(
                      'Экрандар арасындағы баяу өтулерді және карта анимацияларын өшіреді',
                      style: TextStyle(fontSize: 12, color: AtlasColors.muted),
                    ),
                    value: widget.reduceMotion,
                    activeTrackColor: AtlasColors.green,
                    onChanged: widget.onToggleReduceMotion,
                  ),
                ],
              ),
            ),
          ),


          // Match History
          const Text(
            'СОҢҒЫ ЖЕКПЕ-ЖЕКТЕР',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: AtlasColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AtlasColors.line),
            ),
            child: const Text(
              'Сіз әлі бірде-бір жекпе-жек ойнаған жоқсыз. Тарихыңыз сақталуы үшін матчты бастаңыз!',
              style: TextStyle(color: AtlasColors.muted, fontSize: 13),
              textAlign: TextAlign.center,
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
                  'Natural Earth геометриясы (d3-geo). Жарық атлас. Android, iOS және Web.',
                  style: TextStyle(fontSize: 11, color: AtlasColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for bottom dock
        ],
      ),
    );
  }
}
