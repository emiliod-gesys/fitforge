import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        final response = await auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          name: _nameController.text.trim(),
        );
        if (response.session == null && mounted) {
          setState(() => _error = 'Revisa tu email para confirmar la cuenta');
        }
      } else {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      setState(() => _error = 'Credenciales inválidas o email no confirmado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Introduce tu email primero');
      return;
    }
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un enlace para restablecer la contraseña')),
        );
      }
    } catch (_) {
      setState(() => _error = 'No se pudo enviar el email de recuperación');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(Icons.fitness_center, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'FitForge',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu entrenador inteligente en el bolsillo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 48),
              if (_isSignUp)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
              if (_isSignUp) const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submitEmail,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isSignUp ? 'Crear cuenta' : 'Iniciar sesión'),
              ),
              if (!_isSignUp) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading ? null : _resetPassword,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
                }),
                child: Text(_isSignUp ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
