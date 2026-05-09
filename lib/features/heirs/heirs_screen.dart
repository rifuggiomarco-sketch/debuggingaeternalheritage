import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/heir.dart';
import 'heirs_provider.dart';

class HeirsScreen extends ConsumerWidget {
  const HeirsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heirsAsync = ref.watch(heirsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eredi Designati'),
        leading: const BackButton(color: AeternaColors.label),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AeternaColors.gold,
        foregroundColor: AeternaColors.navy,
        icon: const Icon(Icons.person_add),
        label: const Text('Aggiungi Erede',
            style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddHeirSheet(context, ref),
      ),
      body: heirsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AeternaColors.gold)),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AeternaColors.danger))),
        data: (heirs) => heirs.isEmpty
            ? _EmptyHeirsView(
                onAdd: () => _showAddHeirSheet(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: heirs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _HeirCard(
                  heir: heirs[i],
                  onRemove: () =>
                      ref.read(heirsProvider.notifier).removeHeir(heirs[i].id),
                ),
              ),
      ),
    );
  }

  void _showAddHeirSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AeternaColors.navyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddHeirSheet(
        onAdd: (heir) => ref.read(heirsProvider.notifier).addHeir(heir),
      ),
    );
  }
}

class _HeirCard extends StatelessWidget {
  final Heir heir;
  final VoidCallback onRemove;
  const _HeirCard({required this.heir, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AeternaColors.gold.withValues(alpha: 0.15),
            child: Text(
              heir.initials,
              style: const TextStyle(
                color: AeternaColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      heir.fullName,
                      style: const TextStyle(
                        color: AeternaColors.offWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (heir.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AeternaColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Verificato',
                          style: TextStyle(
                            color: AeternaColors.success,
                            fontSize: 10,
                            fontFamily: 'DMM',
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(heir.relationship.label, style: AeternaText.mono.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(heir.email, style: AeternaText.body.copyWith(fontSize: 12)),
                if (heir.canViewAll)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      const Icon(Icons.folder_open_outlined,
                          color: AeternaColors.gold, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Accesso completo al vault',
                        style: TextStyle(
                          color: AeternaColors.gold,
                          fontSize: 11,
                          fontFamily: 'DMM',
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AeternaColors.danger, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddHeirSheet extends StatefulWidget {
  final Function(Heir) onAdd;
  const _AddHeirSheet({required this.onAdd});

  @override
  State<_AddHeirSheet> createState() => _AddHeirSheetState();
}

class _AddHeirSheetState extends State<_AddHeirSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  HeirRelationship _relation = HeirRelationship.other;
  bool _canViewAll = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AeternaColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Nuovo Erede', style: AeternaText.title),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AeternaColors.offWhite),
            decoration: const InputDecoration(labelText: 'Nome completo'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AeternaColors.offWhite),
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<HeirRelationship>(
            initialValue: _relation,
            dropdownColor: AeternaColors.navyDeep,
            style: const TextStyle(color: AeternaColors.offWhite),
            decoration: const InputDecoration(labelText: 'Relazione'),
            items: HeirRelationship.values
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.label),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _relation = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _canViewAll,
                activeThumbColor: AeternaColors.gold,
                onChanged: (v) => setState(() => _canViewAll = v),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Accesso completo al vault',
                  style: TextStyle(color: AeternaColors.label),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) return;
              widget.onAdd(Heir(
                fullName: _nameCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                relationship: _relation,
                canViewAll: _canViewAll,
              ));
              Navigator.pop(context);
            },
            child: const Text('Aggiungi Erede'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHeirsView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHeirsView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AeternaColors.gold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline,
                  color: AeternaColors.gold, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Nessun erede designato', style: AeternaText.title),
            const SizedBox(height: 8),
            Text(
              'Aggiungi almeno un erede per attivare il Dead Man\'s Switch.',
              style: AeternaText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('Aggiungi il primo erede'),
            ),
          ],
        ),
      ),
    );
  }
}
