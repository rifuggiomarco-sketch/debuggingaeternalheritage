// v2.4 — Settings: PIN management, sealed envelope, screenshot toggle, logout.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/services/screenshot_protection.dart';
import '../../core/state/lock_state.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _screenshotBlocked = true;
  bool _hasPin = false;
  bool _hasRecovery = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final pin = await ref.read(pinServiceProvider).isPinSet();
    final rec = await ref.read(recoveryKeyServiceProvider).isSet();
    if (!mounted) return;
    setState(() {
      _hasPin = pin;
      _hasRecovery = rec;
    });
  }

  Future<void> _toggleScreenshot(bool v) async {
    if (v) {
      await ScreenshotProtection.enable();
    } else {
      await ScreenshotProtection.disable();
    }
    setState(() => _screenshotBlocked = v);
  }

  Future<void> _resetPinAndRecovery() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AeternaColors.navyLight,
        title: const Text('Rigenera PIN e Recovery Key',
            style: TextStyle(color: AeternaColors.offWhite)),
        content: const Text(
          'I valori attuali saranno cancellati e dovrai impostarne di nuovi. '
          'Le shares emesse non saranno più valide. Procedere?',
          style: TextStyle(color: AeternaColors.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rigenera',
                style: TextStyle(color: AeternaColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(pinServiceProvider).clearPin();
    await ref.read(recoveryKeyServiceProvider).clear();
    if (!mounted) return;
    context.go('/pin-setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        leading: const BackButton(color: AeternaColors.label),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionLabel(label: 'SICUREZZA'),
          _SettingsTile(
            icon: Icons.pin_outlined,
            title: _hasPin ? 'Cambia PIN' : 'Imposta PIN',
            subtitle: _hasPin
                ? 'PIN attivo · Recovery key ${_hasRecovery ? "presente" : "mancante"}'
                : 'Crea PIN + Recovery Key (4-8 cifre)',
            onTap: () => context.go('/pin-setup'),
          ),
          if (_hasPin)
            _SettingsTile(
              icon: Icons.refresh,
              title: 'Rigenera PIN e Recovery Key',
              subtitle: 'Invalida i valori esistenti',
              onTap: _resetPinAndRecovery,
            ),
          _SettingsTile(
            icon: Icons.fingerprint,
            title: 'Autenticazione biometrica',
            subtitle: 'Face ID / Impronta digitale',
            trailing: Switch(
              value: true,
              activeThumbColor: AeternaColors.gold,
              onChanged: (_) {},
            ),
          ),
          _SettingsTile(
            icon: Icons.no_photography_outlined,
            title: 'Blocca screenshot',
            subtitle: 'FLAG_SECURE attivo (Android)',
            trailing: Switch(
              value: _screenshotBlocked,
              activeThumbColor: AeternaColors.gold,
              onChanged: _toggleScreenshot,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'EREDITÀ'),
          _SettingsTile(
            icon: Icons.mail_lock_outlined,
            title: 'Sealed Envelope',
            subtitle: 'Messaggio sigillato Shamir k-of-n per gli eredi',
            onTap: () => context.go('/sealed-envelope'),
          ),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'VAULT'),
          _SettingsTile(
            icon: Icons.cloud_upload_outlined,
            title: 'Backup cifrato',
            subtitle: 'Sincronizza vault su cloud (E2E)',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Esporta vault',
            subtitle: 'Scarica archivio cifrato .aet',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'ABBONAMENTO'),
          _PremiumCard(),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'INFORMAZIONI'),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            subtitle: 'Come trattiamo i tuoi dati',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Termini di Servizio',
            onTap: () {},
          ),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'Versione',
            subtitle: '2.4.0 — Sealed',
            onTap: null,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              ref.read(lockProvider.notifier).lock();
              context.go('/auth');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AeternaColors.danger),
              foregroundColor: AeternaColors.danger,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Esci'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: AeternaText.label),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AeternaColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AeternaColors.label, size: 22),
        title: Text(title,
            style: const TextStyle(
                color: AeternaColors.offWhite, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AeternaText.body.copyWith(fontSize: 12))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AeternaColors.label)
                : null),
        onTap: onTap,
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AeternaColors.gold.withValues(alpha: 0.15),
            AeternaColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.workspace_premium,
                color: AeternaColors.gold, size: 20),
            const SizedBox(width: 8),
            Text('Piano attuale: Silver', style: AeternaText.label),
          ]),
          const SizedBox(height: 10),
          const Text(
            'Passa a Gold o Legacy per Moral Compass AI avanzato, vault illimitato e verifica notarile.',
            style: TextStyle(
                color: AeternaColors.label, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AeternaColors.gold,
                foregroundColor: AeternaColors.navy,
              ),
              child: const Text('Aggiorna Piano'),
            ),
          ),
        ],
      ),
    );
  }
}
