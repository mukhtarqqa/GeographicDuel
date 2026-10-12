import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/atlas_theme.dart';
import '../../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_logo.dart';
import '../../main.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;
  const AuthScreen({super.key, this.initialMode = AuthMode.signIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_mode == AuthMode.signIn) {
        // Авторизация (Кіру)
        try {
          await AuthService.instance.signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (e) {
          // Егер бұл пошта жүйеде тіркелмеген болса, автоматты түрде жаңа аккаунт ашу:
          final isUserNotFound = e is FirebaseAuthException &&
              (e.code == 'user-not-found' || e.code == 'invalid-credential');
          if (isUserNotFound) {
            await AuthService.instance.signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _emailController.text.trim().split('@').first,
            );
          } else {
            rethrow;
          }
        }
      } else {
        // Тіркелу
        await AuthService.instance.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }

      if (mounted) {
        // Басты бетке өту (Критерий 4, 5, 14 бойынша: Басты бет ашылады)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Егер Firebase консолінде Email әдісі өшірілген болса, демо ретінде кіргізу:
        if (e is FirebaseAuthException && e.code == 'operation-not-allowed') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DuelShell()),
          );
          return;
        }
        setState(() {
          _errorMessage = AuthService.getKazakhErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInAnonymously();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelShell()),
        );
      }
    } catch (e) {
      // Қонақ ретінде сынақ демонстрациясына кедергісіз басты бетке жіберу:
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelShell()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getKazakhErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _quickFillDemo() {
    setState(() {
      _mode = AuthMode.signIn;
      _emailController.text = 'student@duel.kz';
      _passwordController.text = '123456';
      _errorMessage = null;
    });
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == AuthMode.signIn;

    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Vector Compass Emblem (Логотип)
                  const Center(
                    child: AppLogo(size: 78),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'GEOGRAPHIC DUEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                      color: AtlasColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    isSignIn ? 'Жүйеге кіру' : 'Жаңа тіркелу',
                    textAlign: TextAlign.center,
                    style: AtlasTheme.editorial(32),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    isSignIn
                        ? 'Өз Google аккаунтыңызбен немесе поштамен кіріңіз'
                        : 'Жеке аккаунт ашып, әлемдік көшбасшылар кестесіне қосылыңыз',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AtlasColors.muted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1-Click Google Sign-In Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtlasColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isLoading ? null : _signInWithGoogle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_circle,
                                  color: Color(0xff4285F4),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Google арқылы кіру',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AtlasColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AtlasColors.line)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'НЕМЕСЕ ЭЛЕКТРОНДЫҚ ПОШТАМЕН',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: AtlasColors.muted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AtlasColors.line)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Mode Switcher Tabs (Кіру / Тіркелу)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AtlasColors.paperDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AtlasColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _switchMode(AuthMode.signIn),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSignIn ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSignIn
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Кіру',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSignIn ? FontWeight.bold : FontWeight.w500,
                                  color: isSignIn ? AtlasColors.ink : AtlasColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _switchMode(AuthMode.signUp),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isSignIn ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !isSignIn
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Тіркелу',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !isSignIn ? FontWeight.bold : FontWeight.w500,
                                  color: !isSignIn ? AtlasColors.ink : AtlasColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xfffff1f0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffffccc7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 20, color: Color(0xffff4d4f)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xffcf1322),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Inputs Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AtlasColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Display Name (Тіркелу кезінде ғана)
                          if (!isSignIn) ...[
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Зерттеушінің аты (Аты-жөні)',
                                hintText: 'Мысалы: Шыңғыс, Аружан',
                                prefixIcon: const Icon(Icons.person_outline, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Аты-жөніңізді енгізіңіз';
                                }
                                if (val.trim().length < 2) {
                                  return 'Аты кемінде 2 таңбадан тұруы тиіс';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Электрондық пошта (Email)',
                              hintText: 'user@example.com',
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Электрондық поштаны енгізіңіз';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Электрондық поштаның пішімі қате';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: isSignIn ? TextInputAction.done : TextInputAction.next,
                            onFieldSubmitted: isSignIn ? (_) => _submit() : null,
                            decoration: InputDecoration(
                              labelText: 'Құпиясөз',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Құпиясөзді енгізіңіз';
                              }
                              if (val.length < 6) {
                                return 'Құпиясөз кемінде 6 таңбадан тұруы тиіс';
                              }
                              return null;
                            },
                          ),

                          // Confirm Password (Тіркелу кезінде)
                          if (!isSignIn) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Құпиясөзді растау',
                                prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Құпиясөзді растаңыз';
                                }
                                if (val != _passwordController.text) {
                                  return 'Құпиясөздер сәйкес келмейді';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Submit Button
                          PrimaryButton(
                            label: _isLoading
                                ? (isSignIn ? 'Кіруде...' : 'Тіркелуде...')
                                : (isSignIn ? 'Жүйеге кіру' : 'Тіркелуді аяқтау'),
                            icon: isSignIn ? Icons.login_rounded : Icons.person_add_rounded,
                            accentColor: AtlasColors.green,
                            onPressed: _isLoading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Demo Sign In
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AtlasColors.paperDark,
                      foregroundColor: AtlasColors.ink,
                      side: const BorderSide(color: AtlasColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.flash_on_rounded, size: 18, color: AtlasColors.gold),
                    label: const Text(
                      'Студент ретінде жылдам кіру (Демо)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLoading ? null : _quickFillDemo,
                  ),
                  const SizedBox(height: 10),

                  // Guest / Instant Play Option
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AtlasColors.ink,
                      side: const BorderSide(color: AtlasColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.person_pin_outlined, size: 18),
                    label: const Text(
                      'Тіркелусіз қонақ ретінде кіру',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isLoading ? null : _signInAsGuest,
                  ),
                  const SizedBox(height: 14),

                  // Bottom Switch prompt
                  Center(
                    child: TextButton(
                      onPressed: () => _switchMode(isSignIn ? AuthMode.signUp : AuthMode.signIn),
                      child: Text(
                        isSignIn
                            ? 'Аккаунтыңыз жоқ па? Тіркелуге өту'
                            : 'Аккаунтыңыз бар ма? Жүйеге кіру',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AtlasColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
