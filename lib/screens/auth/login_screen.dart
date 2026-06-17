import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
    _nameController.dispose();
    super.dispose();
  }

  void _resetCaptcha() {
    _captchaToken = null;
    _captchaKey.currentState?.reset();
  }

  bool _validateCaptcha() {
    if (!TurnstileConfig.isEnabled) return true;
    if (_captchaToken != null && _captchaToken!.isNotEmpty) return true;
    setState(() => _error = context.l10n.completeSecurityVerification);
    return false;
  }

  Future<void> _submitEmail() async {
    if (!_validateCaptcha()) return;

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
      _resetCaptcha();
      if (mounted) setState(() => _error = context.l10n.authError);
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
    } catch (_) {
      _resetCaptcha();
      if (mounted) setState(() => _error = l10n.passwordResetFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(child: FitForgeLogo.full(height: 140)),
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
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
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
                    const SizedBox(height: 16),
                    TurnstileCaptcha(
                      key: _captchaKey,
                      onTokenChanged: (token) => setState(() => _captchaToken = token),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitEmail,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
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
