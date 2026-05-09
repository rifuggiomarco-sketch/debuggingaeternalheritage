// v2.5 — Enhanced PIN service with rate limiting and improved security
// PIN numerico 4-8 cifre, hashato con PBKDF2 (Hmac-SHA256, 100k iter)
// e salt dedicato persistito in flutter_secure_storage.
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'security_service.dart';

class PinService {
  PinService();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _pinHashKey = 'aeterna_pin_hash_v2';
  static const _pinSaltKey = 'aeterna_pin_salt_v2';
  static const _pinFailKey = 'aeterna_pin_fail_count_v2';
  static const _pinVersionKey = 'aeterna_pin_version';

  static const int _maxAttempts = 5;
  static final SecurityService _security = SecurityService();

  Future<bool> isPinSet() async {
    final h = await _storage.read(key: _pinHashKey);
    return h != null && h.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    // Sanitize input
    pin = _security.sanitizeInput(pin, maxLength: 8);
    _validatePin(pin);
    
    // Migrate old PIN if exists
    await _migrateOldPinIfNeeded();
    
    final salt = _randomBytes(16);
    final hash = await _hash(pin, salt);
    await _storage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _storage.write(key: _pinHashKey, value: base64Encode(hash));
    await _storage.write(key: _pinFailKey, value: '0');
    await _storage.write(key: _pinVersionKey, value: '2');
    
    // Reset rate limit after successful PIN set
    await _security.resetRateLimit('pin');
  }

  /// Verifica il PIN con rate limiting e sicurezza migliorata.
  /// Ritorna il risultato della verifica con gestione tentativi.
  Future<PinVerifyResult> verifyPin(String pin) async {
    // Check rate limiting first
    if (!await _security.checkPinRateLimit()) {
      return PinVerifyResult.rateLimited;
    }

    // Sanitize input
    pin = _security.sanitizeInput(pin, maxLength: 8);
    
    // Migrate old PIN if needed
    await _migrateOldPinIfNeeded();
    
    final fail = int.tryParse(await _storage.read(key: _pinFailKey) ?? '0') ?? 0;
    if (fail >= _maxAttempts) {
      return PinVerifyResult.lockedOut;
    }

    final saltStr = await _storage.read(key: _pinSaltKey);
    final hashStr = await _storage.read(key: _pinHashKey);
    if (saltStr == null || hashStr == null) {
      return PinVerifyResult.notSet;
    }

    final salt = base64Decode(saltStr);
    final expected = base64Decode(hashStr);
    final actual = await _hash(pin, salt);

    final ok = _constantTimeEquals(actual, expected);
    if (ok) {
      await _storage.write(key: _pinFailKey, value: '0');
      // Reset rate limit on successful verification
      await _security.resetRateLimit('pin');
      return PinVerifyResult.success;
    } else {
      await _storage.write(key: _pinFailKey, value: '${fail + 1}');
      if (fail + 1 >= _maxAttempts) {
        return PinVerifyResult.lockedOut;
      }
      return PinVerifyResult.invalid;
    }
  }

  Future<int> remainingAttempts() async {
    final fail = int.tryParse(await _storage.read(key: _pinFailKey) ?? '0') ?? 0;
    return (_maxAttempts - fail).clamp(0, _maxAttempts);
  }

  Future<void> resetLockout() async {
    await _storage.write(key: _pinFailKey, value: '0');
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _pinFailKey);
    await _storage.delete(key: _pinVersionKey);
    await _security.resetRateLimit('pin');
  }

  /// Migrate old PIN format to new version if needed
  Future<void> _migrateOldPinIfNeeded() async {
    final version = await _storage.read(key: _pinVersionKey);
    if (version == '2') return; // Already migrated
    
    // Check for old PIN format
    final oldHash = await _storage.read(key: 'aeterna_pin_hash_v1');
    final oldSalt = await _storage.read(key: 'aeterna_pin_salt_v1');
    
    if (oldHash != null && oldSalt != null) {
      // Migrate to new format
      await _storage.write(key: _pinHashKey, value: oldHash);
      await _storage.write(key: _pinSaltKey, value: oldSalt);
      await _storage.write(key: _pinVersionKey, value: '2');
      
      // Clean up old keys
      await _storage.delete(key: 'aeterna_pin_hash_v1');
      await _storage.delete(key: 'aeterna_pin_salt_v1');
      await _storage.delete(key: 'aeterna_pin_fail_count_v1');
    }
  }

  // ---------- internal ----------

  void _validatePin(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      throw ArgumentError('Il PIN deve avere tra 4 e 8 cifre.');
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw ArgumentError('Il PIN può contenere solo cifre.');
    }
  }

  Future<List<int>> _hash(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return await key.extractBytes();
  }

  List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

enum PinVerifyResult { success, invalid, lockedOut, notSet, rateLimited }
