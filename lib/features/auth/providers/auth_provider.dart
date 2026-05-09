// Simple Auth Provider for Digital Vault Heritage v3.0
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final bool hasMasterPassword;

  const AuthState({
    this.isAuthenticated = false,
    this.hasMasterPassword = false,
  });

  AuthState copyWith({bool? isAuthenticated, bool? hasMasterPassword}) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        hasMasterPassword: hasMasterPassword ?? this.hasMasterPassword,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _hashKey = 'master_hash';
  static const _saltKey = 'auth_salt';

  @override
  AuthState build() {
    _checkStatus();
    return const AuthState();
  }

  Future<void> _checkStatus() async {
    final hash = await _storage.read(key: _hashKey);
    state = AuthState(hasMasterPassword: hash != null);
  }

  Future<void> setMasterPassword(String password) async {
    final saltBytes = _randomBytes(16);
    final hashB64 = await _hash(password, saltBytes);
    await _storage.write(key: _hashKey, value: hashB64);
    await _storage.write(key: _saltKey, value: base64Encode(saltBytes));
    state = const AuthState(isAuthenticated: true, hasMasterPassword: true);
  }

  Future<bool> login(String password) async {
    final storedHash = await _storage.read(key: _hashKey);
    final saltStr = await _storage.read(key: _saltKey);
    if (storedHash == null || saltStr == null) return false;

    final salt = base64Decode(saltStr);
    final inputHash = await _hash(password, salt);

    final ok = _constantTimeEquals(
      base64Decode(inputHash),
      base64Decode(storedHash),
    );
    if (ok) {
      state = const AuthState(isAuthenticated: true, hasMasterPassword: true);
      return true;
    }
    return false;
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }

  // ------- helpers -------
  static Future<String> _hash(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final keyBytes = await key.extractBytes();
    return base64Encode(keyBytes);
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

// Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
