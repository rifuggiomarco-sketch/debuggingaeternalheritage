// v2.4 — Emergency Sealed Envelope.
// L'utente sigilla un messaggio: viene cifrato con una chiave AES random,
// la chiave viene splittata Shamir k-of-n e distribuita agli eredi.
// Solo quando ALMENO k eredi combinano le loro shares, la chiave viene
// ricostruita e il messaggio decifrato. Il payload cifrato risiede
// localmente (e potrà poi essere replicato cloud-side cifrato).
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shamir_service.dart';

class SealedEnvelope {
  final String id;
  final String title;
  final int k;
  final int n;
  final DateTime createdAt;
  final Map<String, String> payload; // cipher/nonce/mac (base64)

  SealedEnvelope({
    required this.id,
    required this.title,
    required this.k,
    required this.n,
    required this.createdAt,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'k': k,
        'n': n,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
      };

  factory SealedEnvelope.fromJson(Map<String, dynamic> j) => SealedEnvelope(
        id: j['id'] as String,
        title: j['title'] as String,
        k: j['k'] as int,
        n: j['n'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        payload: (j['payload'] as Map).cast<String, String>(),
      );
}

class CreatedEnvelope {
  final SealedEnvelope envelope;
  final List<String> heirShares; // base64, 1 per erede — da consegnare
  CreatedEnvelope(this.envelope, this.heirShares);
}

class SealedEnvelopeService {
  SealedEnvelopeService({ShamirService? shamir})
      : _shamir = shamir ?? ShamirService();

  final ShamirService _shamir;
  final AesGcm _aes = AesGcm.with256bits();

  static const _storeKey = 'aeterna_sealed_envelopes_v1';

  Future<CreatedEnvelope> seal({
    required String title,
    required String message,
    required int k,
    required int n,
  }) async {
    if (message.isEmpty) {
      throw ArgumentError('Messaggio vuoto');
    }
    // 1) chiave AES random 32 byte
    final keyBytes = Uint8List.fromList(
      List.generate(32, (_) => Random.secure().nextInt(256)),
    );
    final key = SecretKey(keyBytes);

    // 2) cifra messaggio
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      utf8.encode(message),
      secretKey: key,
      nonce: nonce,
    );
    final payload = {
      'cipher': base64Encode(box.cipherText),
      'nonce': base64Encode(nonce),
      'mac': base64Encode(box.mac.bytes),
    };

    // 3) Shamir split
    final shares = _shamir.split(secret: keyBytes, n: n, k: k);
    final encoded = shares.map((s) => s.toBase64()).toList();

    // 4) persist envelope (senza la chiave)
    final env = SealedEnvelope(
      id: _newId(),
      title: title,
      k: k,
      n: n,
      createdAt: DateTime.now(),
      payload: payload,
    );
    await _persistAdd(env);

    return CreatedEnvelope(env, encoded);
  }

  /// Apre l'envelope se vengono fornite >= k shares.
  Future<String> unseal({
    required SealedEnvelope envelope,
    required List<String> sharesB64,
  }) async {
    if (sharesB64.length < envelope.k) {
      throw StateError(
        'Servono almeno ${envelope.k} shares (forniti ${sharesB64.length}).',
      );
    }
    final shares = sharesB64.map(ShamirShare.fromBase64).toList();
    final keyBytes = _shamir.combine(shares);
    final key = SecretKey(keyBytes);

    final box = SecretBox(
      base64Decode(envelope.payload['cipher']!),
      nonce: base64Decode(envelope.payload['nonce']!),
      mac: Mac(base64Decode(envelope.payload['mac']!)),
    );
    final clear = await _aes.decrypt(box, secretKey: key);
    return utf8.decode(clear);
  }

  Future<List<SealedEnvelope>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SealedEnvelope.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> remove(String id) async {
    final envelopes = await list();
    final filtered = envelopes.where((e) => e.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storeKey,
      jsonEncode(filtered.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistAdd(SealedEnvelope env) async {
    final envelopes = await list();
    envelopes.add(env);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storeKey,
      jsonEncode(envelopes.map((e) => e.toJson()).toList()),
    );
  }

  String _newId() {
    final r = Random.secure();
    final bytes = List.generate(8, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
