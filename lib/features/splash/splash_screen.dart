import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../main.dart';
import '../../data/firebase/firebase_duel_service.dart';
import '../../services/auth_service.dart';
import '../../data/repositories/user_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      if (AuthService.instance.currentUser == null) {
        await AuthService.instance.signInAnonymously();
      }

      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null) {
        await UserRepository.instance.getUserProfile(currentUser.uid);
      }

      await FirebaseDuelService.instance.signInAnonymously();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DuelShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AtlasColors.paper,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AtlasColors.ink),
              const SizedBox(height: 24),
              Text(
                'Connecting to servers...',
                style: AtlasTheme.editorial(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
