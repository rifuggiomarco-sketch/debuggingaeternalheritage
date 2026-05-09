import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyName = 'master_key_v2';
  static const _keyVersionKey = 'master_key_version';

  Future<String> getOrCreateKey() async {
    String? key = await _storage.read(key: _keyName);
    String? version = await _storage.read(key: _keyVersionKey);

    // Force key regeneration if using old weak key format
    if (key != null && version != '2') {
      await _storage.delete(key: _keyName);
      await _storage.delete(key: _keyVersionKey);
      key = null;
    }

    if (key != null) return key;

    key = await _generateStrongKey();
    await _storage.write(key: _keyName, value: key);
    await _storage.write(key: _keyVersionKey, value: '2');

    return key;
  }

  /// Generate cryptographically strong 256-bit key using secure random bytes
  Future<String> _generateStrongKey() async {
    final random = Random.secure();
    final keyBytes = Uint8List(32); // 256 bits
    
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    
    // Use base64url encoding for safe storage and transmission
    return base64Url.encode(keyBytes);
  }

  /// Rotate master key for enhanced security
  Future<String> rotateKey() async {
    await _storage.delete(key: _keyName);
    await _storage.delete(key: _keyVersionKey);
    return await getOrCreateKey();
  }

  /// Verify key strength and format
  bool isValidKeyFormat(String key) {
    try {
      final decoded = base64Url.decode(key);
      return decoded.length == 32; // 256 bits
    } catch (e) {
      return false;
    }
  }
}
