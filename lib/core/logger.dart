// v2.3 — Logger centralizzato.
// REGOLA DI SICUREZZA: NON loggare MAI dati sensibili (master key, PIN,
// recovery key, payload decifrato, contenuto vault). Usa solo metadati e
// messaggi descrittivi (es. 'Vault operation completed').
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warning(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  static void error(String message, [Object? err, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[ERROR] $message${err != null ? ': $err' : ''}');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  static void critical(String message, [Object? err, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[CRITICAL] $message${err != null ? ': $err' : ''}');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  /// Helper per loggare azioni vault SENZA esporre payload.
  /// Esempio: AppLogger.vaultOp('encrypt', success: true);
  static void vaultOp(String op, {required bool success}) {
    if (kDebugMode) {
      debugPrint('[VAULT] op=$op result=${success ? 'ok' : 'fail'}');
    }
  }
}
