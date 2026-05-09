// v2.3 — Stato globale di lock dell'app (Riverpod).
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LockController extends Notifier<bool> {
  // state == true  → unlocked
  // state == false → locked

  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

/// `true` se l'app è sbloccata.
final lockProvider = NotifierProvider<LockController, bool>(
  LockController.new,
);
