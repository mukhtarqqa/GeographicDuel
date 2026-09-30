import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../main.dart';
import '../../data/firebase/firebase_duel_service.dart';

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
