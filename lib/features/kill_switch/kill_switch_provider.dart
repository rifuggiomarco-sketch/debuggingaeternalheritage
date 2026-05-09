// Rinominato da features/switch/ → features/kill_switch/ (bug #9).
// "switch" è parola chiave Dart: causa confusione e potenziali import strani.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logger.dart';

class KillSwitchState {
  final bool isActive;
  final int intervalDays;
  final DateTime? lastCheckIn;
  final int missedCount;

  const KillSwitchState({
    this.isActive = false,
    this.intervalDays = 60,
    this.lastCheckIn,
    this.missedCount = 0,
  });

  DateTime? get nextCheckIn => lastCheckIn?.add(Duration(days: intervalDays));

  KillSwitchState copyWith({
    bool? isActive,
    int? intervalDays,
    DateTime? lastCheckIn,
    int? missedCount,
  }) =>
      KillSwitchState(
        isActive: isActive ?? this.isActive,
        intervalDays: intervalDays ?? this.intervalDays,
        lastCheckIn: lastCheckIn ?? this.lastCheckIn,
        missedCount: missedCount ?? this.missedCount,
      );
}

final killSwitchProvider =
    NotifierProvider<KillSwitchNotifier, KillSwitchState>(
        KillSwitchNotifier.new);

class KillSwitchNotifier extends Notifier<KillSwitchState> {
  @override
  KillSwitchState build() {
    _load();
    return const KillSwitchState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool('switch_active') ?? false;
      final interval = prefs.getInt('switch_interval') ?? 60;
      final lastCheckInMs = prefs.getInt('switch_last_checkin');
      final missed = prefs.getInt('switch_missed') ?? 0;

      state = KillSwitchState(
        isActive: isActive,
        intervalDays: interval,
        lastCheckIn: lastCheckInMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastCheckInMs)
            : null,
        missedCount: missed,
      );
    } catch (e, st) {
      AppLogger.error('KillSwitchNotifier._load', e, st);
    }
  }

  Future<void> activate({required int intervalDays}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setBool('switch_active', true);
      await prefs.setInt('switch_interval', intervalDays);
      await prefs.setInt('switch_last_checkin', now.millisecondsSinceEpoch);
      await prefs.setInt('switch_missed', 0);

      state = KillSwitchState(
        isActive: true,
        intervalDays: intervalDays,
        lastCheckIn: now,
        missedCount: 0,
      );
    } catch (e, st) {
      AppLogger.error('KillSwitchNotifier.activate', e, st);
    }
  }

  Future<void> checkIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt('switch_last_checkin', now.millisecondsSinceEpoch);
      await prefs.setInt('switch_missed', 0);
      state = state.copyWith(lastCheckIn: now, missedCount: 0);
    } catch (e, st) {
      AppLogger.error('KillSwitchNotifier.checkIn', e, st);
    }
  }

  Future<void> deactivate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('switch_active', false);
      state = const KillSwitchState();
    } catch (e, st) {
      AppLogger.error('KillSwitchNotifier.deactivate', e, st);
    }
  }
}
