// v2.3 — Schermata di sblocco vault: biometria → PIN → recovery key.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/services/pin_service.dart';
import '../../core/state/lock_state.dart';
import '../../core/theme/app_theme.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _busy = false;
  bool _showPin = false;
  bool _showRecovery = false;
  String? _error;
  int _remaining = 5;

  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _recoveryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _recoveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (!mounted) return;
    setState(() => _busy = true);

    final auth = ref.read(authServiceProvider);
    final ok = await auth.authenticate(reason: 'Sblocca Aeterna Vault');

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      _onUnlocked();
      return;
    }

    final pinService = ref.read(pinServiceProvider);
    final hasPin = await pinService.isPinSet();
    if (!mounted) return;
    if (hasPin) {
      _remaining = await pinService.remainingAttempts();
      if (!mounted) return;
      setState(() => _showPin = true);
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final pinService = ref.read(pinServiceProvider);
    final result = await pinService.verifyPin(_pinCtrl.text.trim());
    if (!mounted) return;
    _remaining = await pinService.remainingAttempts();

    setState(() => _busy = false);

    switch (result) {
      case PinVerifyResult.success:
        _onUnlocked();
        break;
      case PinVerifyResult.invalid:
        setState(() {
          _error = 'PIN errato. Tentativi rimasti: $_remaining';
          _pinCtrl.clear();
        });
        break;
      case PinVerifyResult.lockedOut:
        setState(() {
          _error = 'Account bloccato per troppi tentativi falliti';
        });
        break;
      case PinVerifyResult.rateLimited:
        setState(() {
          _error = 'Troppi tentativi. Riprova più tardi';
        });
        break;
      case PinVerifyResult.notSet:
        setState(() => _error = 'Nessun PIN impostato.');
        break;
    }
  }

  Future<void> _verifyRecovery() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final svc = ref.read(recoveryKeyServiceProvider);
    final ok = await svc.verify(_recoveryCtrl.text.trim());
    if (!mounted) return;

    if (ok) {
      // reset lockout PIN dopo recovery riuscita
      await ref.read(pinServiceProvider).resetLockout();
      _onUnlocked();
      return;
    }

    setState(() {
      _busy = false;
      _error = 'Recovery key non valida.';
    });
  }

  void _onUnlocked() {
    ref.read(lockProvider.notifier).unlock();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(Icons.lock_outline,
                  color: AeternaColors.gold, size: 48),
              const SizedBox(height: 18),
              Text(
                'Vault bloccato',
                style: AeternaText.headline.copyWith(
                  fontSize: 32,
                  color: AeternaColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sblocca con biometria, PIN o Recovery Key.',
                style: AeternaText.body.copyWith(fontSize: 15),
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
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AeternaColors.danger),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_showPin && !_showRecovery) ...[
                TextField(
                  key: const Key('lock-pin-input'),
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: AeternaColors.offWhite,
                    letterSpacing: 8,
                    fontSize: 22,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('lock-pin-submit'),
                  onPressed: _busy ? null : _verifyPin,
                  child: const Text('Sblocca con PIN'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _showRecovery = true),
                  child: const Text(
                    'Usa Recovery Key',
                    style: TextStyle(color: AeternaColors.gold),
                  ),
                ),
              ],
              if (_showRecovery) ...[
                TextField(
                  key: const Key('lock-recovery-input'),
                  controller: _recoveryCtrl,
                  style: const TextStyle(
                    color: AeternaColors.offWhite,
                    fontFamily: 'DMM',
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Recovery Key',
                    hintText: 'XXXXX-XXXXX-XXXXX-XXXXX-...',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('lock-recovery-submit'),
                  onPressed: _busy ? null : _verifyRecovery,
                  child: const Text('Sblocca con Recovery Key'),
                ),
              ],
              if (!_showPin && !_showRecovery) ...[
                ElevatedButton.icon(
                  onPressed: _busy ? null : _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(_busy ? 'Verifica...' : 'Sblocca con biometria'),
                ),
              ],
              if (!_busy && !_showPin && !_showRecovery) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showPin = true),
                    child: const Text(
                      'Usa PIN',
                      style: TextStyle(color: AeternaColors.gold),
                    ),
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(
                  child:
                      CircularProgressIndicator(color: AeternaColors.gold),
                ),
              ],
              const Spacer(),
              Center(
                child: Text(
                  'Auto-lock 30s · AES-256-GCM',
                  style: AeternaText.mono,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
