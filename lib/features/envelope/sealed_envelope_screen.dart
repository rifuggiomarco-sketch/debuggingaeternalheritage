// v2.4 — UI Sealed Envelope: crea (titolo, messaggio, k, n) e mostra le shares
// da consegnare agli eredi. Le shares vengono mostrate UNA volta sola.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/services/sealed_envelope_service.dart';
import '../../core/theme/app_theme.dart';

class SealedEnvelopeScreen extends ConsumerStatefulWidget {
  const SealedEnvelopeScreen({super.key});

  @override
  ConsumerState<SealedEnvelopeScreen> createState() =>
      _SealedEnvelopeScreenState();
}

class _SealedEnvelopeScreenState extends ConsumerState<SealedEnvelopeScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  int _n = 3;
  int _k = 2;
  bool _busy = false;
  CreatedEnvelope? _created;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _seal() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'Titolo e messaggio richiesti');
      return;
    }
    if (_k < 2 || _k > _n) {
      setState(() => _error = 'k deve essere ≥ 2 e ≤ n');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final svc = ref.read(sealedEnvelopeServiceProvider);
      final created = await svc.seal(
        title: _title.text.trim(),
        message: _message.text.trim(),
        k: _k,
        n: _n,
      );
      if (!mounted) return;
      setState(() {
        _created = created;
        _busy = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sealed Envelope'),
        leading: const BackButton(color: AeternaColors.label),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _created == null ? _buildForm() : _buildShares(_created!),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crea un envelope sigillato', style: AeternaText.title),
        const SizedBox(height: 6),
        Text(
          'Il messaggio sarà cifrato con AES-256-GCM. La chiave sarà '
          'splittata in $_n parti — solo $_k eredi insieme potranno aprirlo.',
          style: AeternaText.body,
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AeternaColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AeternaColors.danger),
            ),
            child: Text(_error!, style: const TextStyle(color: AeternaColors.danger)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const Key('envelope-title'),
          controller: _title,
          style: const TextStyle(color: AeternaColors.offWhite),
          decoration: const InputDecoration(labelText: 'Titolo'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('envelope-message'),
          controller: _message,
          maxLines: 6,
          style: const TextStyle(color: AeternaColors.offWhite),
          decoration: const InputDecoration(
            labelText: 'Messaggio (resterà cifrato)',
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _NumberPicker(
                label: 'Eredi totali (n)',
                value: _n,
                min: 2,
                max: 10,
                onChanged: (v) => setState(() {
                  _n = v;
                  if (_k > _n) _k = _n;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberPicker(
                label: 'Quorum (k)',
                value: _k,
                min: 2,
                max: _n,
                onChanged: (v) => setState(() => _k = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          key: const Key('envelope-seal'),
          onPressed: _busy ? null : _seal,
          child: Text(_busy ? 'Sigillo...' : 'Sigilla envelope'),
        ),
      ],
    );
  }

  Widget _buildShares(CreatedEnvelope created) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, color: AeternaColors.gold, size: 40),
        const SizedBox(height: 12),
        Text('Envelope sigillato', style: AeternaText.title),
        const SizedBox(height: 6),
        Text(
          'Consegna UNA share a ciascun erede. Servono almeno '
          '${created.envelope.k} di ${created.envelope.n} per aprire.',
          style: AeternaText.body,
        ),
        const SizedBox(height: 20),
        ...created.heirShares.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AeternaColors.navyLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AeternaColors.gold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Erede ${e.key + 1}', style: AeternaText.label),
                    const SizedBox(height: 6),
                    SelectableText(
                      e.value,
                      style: const TextStyle(
                        fontFamily: 'DMM',
                        color: AeternaColors.offWhite,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: e.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Share ${e.key + 1} copiata')),
                          );
                        },
                        icon: const Icon(Icons.copy,
                            color: AeternaColors.gold, size: 16),
                        label: const Text('Copia',
                            style: TextStyle(color: AeternaColors.gold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Ho consegnato le shares — Continua'),
        ),
      ],
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AeternaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AeternaText.label),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove, color: AeternaColors.gold),
              ),
              Text('$value',
                  style: AeternaText.title.copyWith(fontSize: 22)),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add, color: AeternaColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
