// v2.3 — Setup PIN + generazione Recovery Key (mostrata UNA volta).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _recoveryKey;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final pin = _pin.text.trim();
    if (pin.length < 4 || pin.length > 8) {
      setState(() {
        _busy = false;
        _error = 'Il PIN deve avere tra 4 e 8 cifre.';
      });
      return;
    }
    if (pin != _confirm.text.trim()) {
      setState(() {
        _busy = false;
        _error = 'I PIN non corrispondono.';
      });
      return;
    }

    try {
      await ref.read(pinServiceProvider).setPin(pin);
      final key = await ref.read(recoveryKeyServiceProvider).generateAndStore();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recoveryKey = key;
      });
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
    if (_recoveryKey != null) {
      return _RecoveryKeyView(
        recoveryKey: _recoveryKey!,
        onDone: () => context.go('/home'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imposta PIN'),
        leading: const BackButton(color: AeternaColors.label),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crea un PIN di sblocco',
                style: AeternaText.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                'Verrà richiesto se la biometria non è disponibile. '
                'Genereremo anche una Recovery Key in caso di smarrimento.',
                style: AeternaText.body,
              ),
              const SizedBox(height: 28),
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
              TextField(
                key: const Key('pin-setup-input'),
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AeternaColors.offWhite,
                  letterSpacing: 8,
                  fontSize: 22,
                ),
                decoration: const InputDecoration(
                  labelText: 'PIN (4-8 cifre)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('pin-confirm-input'),
                controller: _confirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AeternaColors.offWhite,
                  letterSpacing: 8,
                  fontSize: 22,
                ),
                decoration: const InputDecoration(
                  labelText: 'Conferma PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('pin-setup-save'),
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Salvo...' : 'Salva PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryKeyView extends StatelessWidget {
  final String recoveryKey;
  final VoidCallback onDone;
  const _RecoveryKeyView({required this.recoveryKey, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.key, color: AeternaColors.gold, size: 48),
              const SizedBox(height: 16),
              Text(
                'Recovery Key',
                style: AeternaText.headline.copyWith(
                  fontSize: 28,
                  color: AeternaColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Salva questa chiave in un posto sicuro. È l\'UNICO modo per '
                'rientrare nel vault se dimentichi il PIN. Non potremo mostrarla '
                'di nuovo.',
                style: AeternaText.body,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AeternaColors.navyLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AeternaColors.gold),
                ),
                child: SelectableText(
                  recoveryKey,
                  key: const Key('recovery-key-display'),
                  style: const TextStyle(
                    color: AeternaColors.offWhite,
                    fontFamily: 'DMM',
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recoveryKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recovery key copiata'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: AeternaColors.gold),
                label: const Text(
                  'Copia',
                  style: TextStyle(color: AeternaColors.gold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AeternaColors.gold),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                key: const Key('recovery-key-done'),
                onPressed: onDone,
                child: const Text('Ho salvato la chiave — Continua'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
