import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../services/auth_service.dart';
import '../auth/auth_screen.dart';
import '../widgets/app_logo.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _initAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    try {
      // 1.2 секунд таныстыру логотипі мен жүйе инициализациясы
      await Future.delayed(const Duration(milliseconds: 1200));

      final currentUser = AuthService.instance.currentUser;

      if (!mounted) return;

      // Тек нақты тіркелген (Google немесе Email) аккаунт болғанда ғана басты бетке өтеді.
      // Қонақ (анонимді) аккаунттарға қамалып қалмас үшін әрдайым AuthScreen ашылады.
      if (currentUser != null && !currentUser.isAnonymous) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    } catch (e) {
      debugPrint('Іске қосу ескертпесі: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Compass Emblem
              const AppLogo(size: 96),
              const SizedBox(height: 24),

              // Title
              const Text(
                'GEOGRAPHIC DUEL',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.bold,
                  color: AtlasColors.muted,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Жарық атлас',
                style: AtlasTheme.editorial(32),
              ),
              const SizedBox(height: 8),

              const Text(
                'Географиялық дуэль және әлемді тану',
                style: TextStyle(
                  fontSize: 13,
                  color: AtlasColors.inkLight,
                ),
              ),
              const SizedBox(height: 36),

              // Loading Spinner
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AtlasColors.green),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Жүйеге қосылуда...',
                style: TextStyle(
                  fontSize: 12,
                  color: AtlasColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
