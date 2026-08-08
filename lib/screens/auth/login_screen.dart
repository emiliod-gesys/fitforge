import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/google_auth_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/constants/turnstile_config.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_logo.dart';
import '../../widgets/turnstile_captcha.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _captchaKey = GlobalKey<TurnstileCaptchaState>();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  String? _captchaToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _resetCaptcha() {
    _captchaToken = null;
    _captchaKey.currentState?.reset();
  }

  bool get _captchaReady =>
      !TurnstileConfig.isEnabled ||
      (_captchaToken != null && _captchaToken!.isNotEmpty);

  void _onCaptchaTokenChanged(String? token) {
    setState(() {
      _captchaToken = token;
      if (token != null && token.isNotEmpty) {
        final msg = _error;
        if (msg == context.l10n.completeSecurityVerification ||
            (msg != null && msg.toLowerCase().contains('captcha'))) {
          _error = null;
        }
      }
    });
  }

  bool _validateCaptcha() {
    if (_captchaReady) return true;
    setState(() => _error = context.l10n.completeSecurityVerification);
    return false;
  }

  /// Solo recrea el WebView cuando el token ya no sirve; evita bucles al fallar
  /// credenciales con un captcha aún válido.
  bool _shouldResetCaptchaAfterError(Object error) {
    if (!TurnstileConfig.isEnabled) return false;
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('captcha') ||
          message.contains('invalid-input') ||
          message.contains('timeout-or-duplicate')) {
        return true;
      }
    }
    return _captchaToken != null;
  }

  String _authErrorMessage(Object error) {
    final l10n = context.l10n;
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'Email o contraseña incorrectos.';
      }
      if (message.contains('captcha')) {
        if (!TurnstileConfig.isEnabled) {
          return 'El servidor aún exige verificación CAPTCHA. '
              'En Supabase desactiva Auth → Protection → Enable CAPTCHA protection.';
        }
        if (message.contains('invalid-input') || message.contains('timeout-or-duplicate')) {
          return 'El servidor rechazó la verificación. En Supabase → Auth → Protection '
              'usa el Secret key de prueba 1x0000000000000000000000000000000AA '
              'o desactiva CAPTCHA.';
        }
        return l10n.completeSecurityVerification;
      }
      if (message.contains('email not confirmed')) {
        return 'Confirma tu email antes de iniciar sesión.';
      }
      if (kDebugMode) return '${l10n.authError} (${error.message})';
    }
    return l10n.authError;
  }

  Future<void> _submitEmail() async {
    if (!_validateCaptcha()) return;

    final l10n = context.l10n;
    if (_isSignUp && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          name: _nameController.text.trim(),
          captchaToken: _captchaToken,
        );
      } else {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          captchaToken: _captchaToken,
        );
      }
      _resetCaptcha();
    } catch (e) {
      if (_shouldResetCaptchaAfterError(e)) {
        _resetCaptcha();
      }
      if (mounted) setState(() => _error = _authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_validateCaptcha()) return;

    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.enterEmailFirst);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(
            email,
            captchaToken: _captchaToken,
          );
      _resetCaptcha();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordResetSent)),
        );
      }
    } catch (e) {
      if (_shouldResetCaptchaAfterError(e)) {
        _resetCaptcha();
      }
      if (mounted) setState(() => _error = l10n.passwordResetFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      if (e is AuthException && e.message.toLowerCase().contains('cancel')) {
        setState(() => _error = context.l10n.googleSignInCancelled);
      } else {
        setState(() => _error = context.l10n.googleSignInFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(child: FitForgeLogo.full(height: 148)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loginTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppDecorations.authCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignUp ? l10n.createAccount : l10n.signIn,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (_isSignUp)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: l10n.name),
                      ),
                    if (_isSignUp) const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(labelText: l10n.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.password),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: l10n.confirmPassword),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TurnstileCaptcha(
                      key: _captchaKey,
                      onTokenChanged: _onCaptchaTokenChanged,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_loading || !_captchaReady) ? null : _submitEmail,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(_isSignUp ? l10n.createAccount : l10n.enter),
                    ),
                    if (!_isSignUp) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: Text(l10n.forgotPassword),
                      ),
                    ],
                  ],
                ),
              ),
              if (GoogleAuthConfig.enabled) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.orContinueWith,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                  label: Text(
                    l10n.continueWithGoogle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
                  _confirmPasswordController.clear();
                  _resetCaptcha();
                }),
                child: Text(_isSignUp ? l10n.haveAccountSignIn : l10n.noAccountSignUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
