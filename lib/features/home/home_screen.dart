// Bug #9 fix: import aggiornato a kill_switch — rimosso riferimento a features/switch/.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../vault/vault_provider.dart';
import '../heirs/heirs_provider.dart';
import '../kill_switch/kill_switch_provider.dart';
import '../../shared/models/heir.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider);
    final heirsAsync = ref.watch(heirsProvider);
    final switchState = ref.watch(killSwitchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aeterna Protocol'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AeternaColors.label),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AeternaColors.gold,
        backgroundColor: AeternaColors.navyLight,
        onRefresh: () async {
          ref.invalidate(vaultProvider);
          ref.invalidate(heirsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SwitchStatusCard(state: switchState),
            const SizedBox(height: 16),
            _QuickActions(),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Il tuo Vault',
              action: 'Vedi tutti',
              onTap: () => context.goNamed('vault'),
            ),
            const SizedBox(height: 12),
            vaultAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (docs) => _VaultSummaryCard(docCount: docs.length),
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Eredi designati',
              action: 'Gestisci',
              onTap: () => context.goNamed('heirs'),
            ),
            const SizedBox(height: 12),
            heirsAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (heirs) => heirs.isEmpty
                  ? _EmptyHeirsCard(onTap: () => context.goNamed('heirs'))
                  : Column(
                      children: heirs
                          .take(3)
                          .map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _HeirTile(
                                  name: h.fullName,
                                  relationship: h.relationship.label,
                                  isVerified: h.isVerified,
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SwitchStatusCard extends StatelessWidget {
  final KillSwitchState state;
  const _SwitchStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isActive = state.isActive;
    final statusColor =
        isActive ? AeternaColors.success : AeternaColors.warning;
    final nextDate = state.nextCheckIn;
    final daysLeft = nextDate?.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AeternaColors.gold : AeternaColors.warning,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEAD MAN\'S SWITCH', style: AeternaText.label),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'ATTIVO' : 'NON CONFIGURATO',
                  style: TextStyle(
                    fontFamily: 'DMM',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isActive && daysLeft != null) ...[
            Text(
              'Prossimo check-in tra',
              style: AeternaText.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '$daysLeft giorni',
              style: AeternaText.title.copyWith(
                fontSize: 32,
                color: AeternaColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy', 'it').format(nextDate!),
              style: AeternaText.mono,
            ),
          ] else ...[
            Text(
              'Configura il timer per proteggere il tuo vault',
              style: AeternaText.body,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.goNamed('switch'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AeternaColors.gold),
                  foregroundColor: AeternaColors.gold,
                ),
                child: const Text('Configura adesso'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.upload_file_outlined,
            label: 'Carica\nDocumento',
            onTap: () => context.goNamed('vault'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.people_outline,
            label: 'Aggiungi\nErede',
            onTap: () => context.goNamed('heirs'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.timer_outlined,
            label: 'Imposta\nTimer',
            onTap: () => context.goNamed('switch'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AeternaColors.navyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AeternaColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AeternaColors.gold, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: AeternaText.body.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;
  const _SectionHeader(
      {required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AeternaText.subtitle),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: AeternaColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _VaultSummaryCard extends StatelessWidget {
  final int docCount;
  const _VaultSummaryCard({required this.docCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AeternaColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline,
                color: AeternaColors.gold, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$docCount document${docCount != 1 ? 'i' : 'o'}',
                style: AeternaText.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text('Tutti cifrati AES-256-GCM', style: AeternaText.mono),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AeternaColors.label),
        ],
      ),
    );
  }
}

class _HeirTile extends StatelessWidget {
  final String name;
  final String relationship;
  final bool isVerified;
  const _HeirTile(
      {required this.name,
      required this.relationship,
      required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').length >= 2
        ? '${name.split(' ').first[0]}${name.split(' ').last[0]}'.toUpperCase()
        : name.substring(0, 2).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AeternaColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AeternaColors.gold.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: AeternaColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AeternaText.subtitle.copyWith(fontSize: 15)),
                Text(relationship,
                    style: AeternaText.mono.copyWith(fontSize: 12)),
              ],
            ),
          ),
          if (isVerified)
            const Icon(Icons.verified_outlined,
                color: AeternaColors.success, size: 18),
        ],
      ),
    );
  }
}

class _EmptyHeirsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyHeirsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AeternaColors.navyLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AeternaColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_add_outlined, color: AeternaColors.gold),
            const SizedBox(width: 12),
            Text(
              'Aggiungi il primo erede',
              style: AeternaText.body.copyWith(color: AeternaColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AeternaColors.gold,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AeternaColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.danger.withValues(alpha: 0.4)),
      ),
      child: Text(message,
          style: const TextStyle(color: AeternaColors.danger)),
    );
  }
}
