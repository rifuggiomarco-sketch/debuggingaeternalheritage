// Rinominato da features/switch/ → features/kill_switch/ (bug #9).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import 'kill_switch_provider.dart';

class KillSwitchScreen extends ConsumerStatefulWidget {
  const KillSwitchScreen({super.key});

  @override
  ConsumerState<KillSwitchScreen> createState() => _KillSwitchScreenState();
}

class _KillSwitchScreenState extends ConsumerState<KillSwitchScreen> {
  int _selectedInterval = 60;
  final _intervals = [30, 45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(killSwitchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dead Man\'s Switch'),
        leading: const BackButton(color: AeternaColors.label),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoCard(),
          const SizedBox(height: 24),
          if (state.isActive)
            _ActiveStatus(state: state)
          else
            _SetupCard(
              selectedInterval: _selectedInterval,
              intervals: _intervals,
              onIntervalChanged: (v) => setState(() => _selectedInterval = v),
              onActivate: () => ref
                  .read(killSwitchProvider.notifier)
                  .activate(intervalDays: _selectedInterval),
            ),
          const SizedBox(height: 16),
          if (state.isActive) ...[
            ElevatedButton.icon(
              onPressed: () => ref.read(killSwitchProvider.notifier).checkIn(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Conferma presenza — Check-in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _confirmDeactivate(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AeternaColors.danger),
                foregroundColor: AeternaColors.danger,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Disattiva Switch'),
            ),
          ],
          const SizedBox(height: 32),
          _HowItWorksCard(),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AeternaColors.navyLight,
        title: const Text('Disattiva Switch',
            style: TextStyle(color: AeternaColors.offWhite)),
        content: const Text(
          'I tuoi eredi non potranno più accedere automaticamente al vault. Sei sicuro?',
          style: TextStyle(color: AeternaColors.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disattiva',
                style: TextStyle(color: AeternaColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(killSwitchProvider.notifier).deactivate();
    }
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AeternaColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, color: AeternaColors.gold, size: 18),
            const SizedBox(width: 8),
            Text('Come funziona', style: AeternaText.label),
          ]),
          const SizedBox(height: 10),
          Text(
            'Il sistema ti invia un check-in ogni X giorni. Se non rispondi per 3 cicli consecutivi, sblocca automaticamente il vault per gli eredi designati.',
            style: AeternaText.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final int selectedInterval;
  final List<int> intervals;
  final ValueChanged<int> onIntervalChanged;
  final VoidCallback onActivate;

  const _SetupCard({
    required this.selectedInterval,
    required this.intervals,
    required this.onIntervalChanged,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Intervallo di check-in', style: AeternaText.subtitle),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: intervals.map((d) {
            final selected = d == selectedInterval;
            return GestureDetector(
              onTap: () => onIntervalChanged(d),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AeternaColors.gold.withValues(alpha: 0.15)
                      : AeternaColors.navyLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AeternaColors.gold : AeternaColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '$d gg',
                  style: TextStyle(
                    color: selected ? AeternaColors.gold : AeternaColors.label,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onActivate,
          icon: const Icon(Icons.timer_outlined),
          label: Text('Attiva Switch ($selectedInterval giorni)'),
        ),
      ],
    );
  }
}

class _ActiveStatus extends StatelessWidget {
  final KillSwitchState state;
  const _ActiveStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final next = state.nextCheckIn;
    final daysLeft = next?.difference(DateTime.now()).inDays ?? 0;
    final progress = 1.0 - (daysLeft / state.intervalDays).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AeternaColors.navyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AeternaColors.success.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SWITCH ATTIVO', style: AeternaText.label),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AeternaColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$daysLeft giorni al prossimo check-in',
                style: AeternaText.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AeternaColors.border,
                  color: daysLeft > 7
                      ? AeternaColors.success
                      : AeternaColors.warning,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              if (next != null)
                Text(
                  'Scadenza: ${DateFormat('dd MMM yyyy', 'it').format(next)}',
                  style: AeternaText.mono,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flusso di attivazione', style: AeternaText.subtitle),
          const SizedBox(height: 16),
          _Step(n: '1', text: 'Check-in notifica inviata ogni X giorni'),
          _Step(n: '2', text: 'Avviso urgente dopo il 1° ciclo mancato'),
          _Step(n: '3', text: 'Secondo avviso dopo il 2° ciclo mancato'),
          _Step(
              n: '4',
              text: 'Sblocco vault al 3° ciclo mancato',
              isLast: true),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  final bool isLast;
  const _Step({required this.n, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AeternaColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AeternaColors.gold.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  n,
                  style: const TextStyle(
                    color: AeternaColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 1, height: 20, color: AeternaColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(text, style: AeternaText.body.copyWith(fontSize: 14)),
        ),
      ],
    );
  }
}
