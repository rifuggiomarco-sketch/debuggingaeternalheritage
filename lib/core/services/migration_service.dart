// v2.4 — Migrazione vault da salt hardcoded (v2.2) a salt random (v2.3+).
// Chiamata al primo unlock dopo upgrade. Idempotente: usa flag persistito.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';
import 'encryption_service.dart';
import 'secure_crypto_storage.dart';
import 'secure_key_service.dart';

class MigrationService {
  MigrationService({
    required this.encryption,
    required this.keyService,
    required this.cryptoStorage,
  });

  final EncryptionService encryption;
  final SecureKeyService keyService;
  final SecureCryptoStorage cryptoStorage;

  static const _flagKey = 'aeterna_migration_v23_done';
  static const _legacySalt = 'aeterna_salt'; // <-- salt v2.2 hardcoded
  static const _vaultDocsKey = 'aeterna_vault_docs';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Esegue la migrazione se non è già stata fatta.
  /// Ritorna true se ha fatto qualcosa, false se già migrato/non necessario.
  Future<bool> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_flagKey) == true) return false;

    try {
      final masterKey = await keyService.getOrCreateKey();

      // Chiave legacy (vecchio salt)
      final legacyKey = await encryption.deriveKey(
        masterKey,
        utf8.encode(_legacySalt),
      );

      // Nuova chiave (salt random salvato)
      final newSalt = await cryptoStorage.getOrCreateSalt();
      final newKey = await encryption.deriveKey(masterKey, newSalt);

      // Migra eventuali blob cifrati salvati in secure_storage con prefix
      // 'enc:' (convenzione della v2.2).
      final all = await _storage.readAll();
      var migrated = 0;
      for (final entry in all.entries) {
        if (!entry.key.startsWith('enc:')) continue;
        try {
          final payload =
              (jsonDecode(entry.value) as Map).cast<String, String>();
          final clear = await encryption.decrypt(
            payload: payload,
            key: legacyKey,
          );
          final reEncrypted = await encryption.encrypt(
            data: clear,
            key: newKey,
          );
          await _storage.write(
            key: entry.key,
            value: jsonEncode(reEncrypted),
          );
          migrated++;
        } catch (_) {
          // record non migrabile (es. già nuovo formato): lo lasciamo intatto
        }
      }

      AppLogger.info('Migration v2.3 completed. items=$migrated');
      await prefs.setBool(_flagKey, true);
      return true;
    } catch (e, st) {
      AppLogger.error('Migration v2.3 failed', e, st);
      return false;
    }
  }
}
