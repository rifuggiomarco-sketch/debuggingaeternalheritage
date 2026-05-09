// v2.4 — AuthScreen ripulita: usa authProvider (Riverpod) invece di metodi
// statici inesistenti su EncryptionService. Sblocca il vault e va a /home.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/lock_state.dart';
import '../../core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit({required bool isFirstTime}) async {
    final pwd = _passwordController.text.trim();
    if (pwd.length < 8) {
      setState(() => _error = 'Password di almeno 8 caratteri');
      return;
    }
    if (isFirstTime && pwd != _confirmController.text.trim()) {
      setState(() => _error = 'Le password non corrispondono');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final notifier = ref.read(authProvider.notifier);
      if (isFirstTime) {
        await notifier.setMasterPassword(pwd);
      } else {
        final ok = await notifier.login(pwd);
        if (!ok) {
          setState(() {
            _busy = false;
            _error = 'Password errata';
          });
          return;
        }
      }
      ref.read(lockProvider.notifier).unlock();
      if (!mounted) return;
      if (isFirstTime) {
        // Onboarding: dopo password → setup PIN/Recovery Key
        context.go('/pin-setup');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Errore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isFirstTime = !auth.hasMasterPassword;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Aeterna',
                style: AeternaText.headline.copyWith(
                  fontSize: 40,
                  color: AeternaColors.gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFirstTime
                    ? 'Imposta la tua master password.\nNon dimenticarla — non è recuperabile.'
                    : 'Accedi al tuo vault.',
                style: AeternaText.body.copyWith(fontSize: 16),
              ),
              const Spacer(),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AeternaColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AeternaColors.danger),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AeternaColors.danger)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                key: const Key('auth-password'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AeternaColors.offWhite),
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AeternaColors.label,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (isFirstTime) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const Key('auth-confirm'),
                  controller: _confirmController,
                  obscureText: true,
                  style: const TextStyle(color: AeternaColors.offWhite),
                  decoration: const InputDecoration(
                    labelText: 'Conferma Password',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('auth-submit'),
                onPressed:
                    _busy ? null : () => _handleSubmit(isFirstTime: isFirstTime),
                child: Text(_busy
                    ? 'Verifico...'
                    : (isFirstTime ? 'Configura Vault' : 'Accedi')),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Crittografia AES-256-GCM — Zero Knowledge',
                  style: AeternaText.mono,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
