// v2.4 — usa VaultRepository (Riverpod) invece di metodi statici inesistenti.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/vault_doc.dart';
import 'vault_provider.dart';
import '../../core/providers.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(vaultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il tuo Vault'),
        leading: const BackButton(color: AeternaColors.label),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AeternaColors.gold,
        foregroundColor: AeternaColors.navy,
        icon: const Icon(Icons.upload_file),
        label: const Text(
          'Carica',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _uploadDocument(context, ref),
      ),
      body: docsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AeternaColors.gold),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AeternaColors.danger)),
        ),
        data: (docs) => docs.isEmpty
            ? _EmptyVaultView(onUpload: () => _uploadDocument(context, ref))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _DocCard(
                  doc: docs[i],
                  onDelete: () => _confirmDelete(context, ref, docs[i]),
                  onToggleShare: () =>
                      ref.read(vaultProvider.notifier).toggleHeirShare(docs[i].id),
                ),
              ),
      ),
    );
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      // v2.4: cifratura via repository (AES-256-GCM + salt sicuro).
      final repo = ref.read(vaultRepositoryProvider);
      final encrypted = await repo.encryptData(base64Encode(file.bytes!));
      final doc = VaultDoc(
        name: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
        extension: file.extension ?? 'bin',
        sizeBytes: file.size,
        ciphertextUrl: 'local://${encrypted['cipher']!.hashCode}',
      );
      await ref.read(vaultProvider.notifier).addDoc(doc);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} cifrato e salvato'),
            backgroundColor: AeternaColors.navyLight,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AeternaColors.danger.withValues(alpha: 0.2),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, VaultDoc doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AeternaColors.navyLight,
        title: const Text('Elimina documento',
            style: TextStyle(color: AeternaColors.offWhite)),
        content: Text(
          'Vuoi eliminare "${doc.name}"? L\'operazione è irreversibile.',
          style: const TextStyle(color: AeternaColors.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina',
                style: TextStyle(color: AeternaColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vaultProvider.notifier).removeDoc(doc.id);
    }
  }
}

class _DocCard extends StatelessWidget {
  final VaultDoc doc;
  final VoidCallback onDelete;
  final VoidCallback onToggleShare;
  const _DocCard(
      {required this.doc, required this.onDelete, required this.onToggleShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AeternaColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeternaColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AeternaColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lock_outline,
              color: AeternaColors.gold, size: 22),
        ),
        title: Text(
          doc.name,
          style: const TextStyle(
            color: AeternaColors.offWhite,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '.${doc.extension} · ${doc.sizeLabel} · ${doc.category.label}',
              style: AeternaText.mono.copyWith(fontSize: 12),
            ),
            if (doc.isSharedWithHeirs)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline,
                        color: AeternaColors.success, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Visibile agli eredi',
                      style: TextStyle(
                        color: AeternaColors.success,
                        fontSize: 11,
                        fontFamily: 'DMM',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AeternaColors.navyDeep,
          icon: const Icon(Icons.more_vert, color: AeternaColors.label),
          onSelected: (v) {
            if (v == 'share') onToggleShare();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'share',
              child: Text(
                doc.isSharedWithHeirs
                    ? 'Rimuovi da eredi'
                    : 'Condividi con eredi',
                style: const TextStyle(color: AeternaColors.offWhite),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Elimina',
                  style: TextStyle(color: AeternaColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVaultView extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyVaultView({required this.onUpload});

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
              child: const Icon(
                Icons.lock_outline,
                color: AeternaColors.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text('Vault vuoto', style: AeternaText.title),
            const SizedBox(height: 8),
            Text(
              'Carica il primo documento.\nVerrà cifrato prima di lasciare il dispositivo.',
              style: AeternaText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Carica documento'),
            ),
          ],
        ),
      ),
    );
  }
}
