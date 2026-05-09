// v2.5 - Enhanced Dead Man's Switch Service
// Provides robust heartbeat mechanism with fail-safe logic and security
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger.dart';
import 'security_service.dart';

class DeadMansSwitchConfig {
  final int intervalDays;
  final int gracePeriodDays;
  final List<String> heirEmails;
  final bool requireMultipleConfirmations;
  final int requiredConfirmations;
  
  const DeadMansSwitchConfig({
    this.intervalDays = 60,
    this.gracePeriodDays = 7,
    this.heirEmails = const [],
    this.requireMultipleConfirmations = true,
    this.requiredConfirmations = 2,
  });
  
  Map<String, dynamic> toJson() => {
    'intervalDays': intervalDays,
    'gracePeriodDays': gracePeriodDays,
    'heirEmails': heirEmails,
    'requireMultipleConfirmations': requireMultipleConfirmations,
    'requiredConfirmations': requiredConfirmations,
  };
  
  factory DeadMansSwitchConfig.fromJson(Map<String, dynamic> json) => DeadMansSwitchConfig(
    intervalDays: json['intervalDays'] as int? ?? 60,
    gracePeriodDays: json['gracePeriodDays'] as int? ?? 7,
    heirEmails: (json['heirEmails'] as List<dynamic>?)?.cast<String>() ?? [],
    requireMultipleConfirmations: json['requireMultipleConfirmations'] as bool? ?? true,
    requiredConfirmations: json['requiredConfirmations'] as int? ?? 2,
  );
}

class DeadMansSwitchState {
  final bool isActive;
  final DateTime? lastCheckIn;
  final DateTime? lastNotification;
  final int missedCheckIns;
  final DeadMansSwitchConfig config;
  final List<HeirConfirmation> heirConfirmations;
  
  const DeadMansSwitchState({
    this.isActive = false,
    this.lastCheckIn,
    this.lastNotification,
    this.missedCheckIns = 0,
    this.config = const DeadMansSwitchConfig(),
    this.heirConfirmations = const [],
  });
  
  DateTime? get nextCheckIn => lastCheckIn?.add(Duration(days: config.intervalDays));
  DateTime? get gracePeriodEnd => nextCheckIn?.add(Duration(days: config.gracePeriodDays));
  bool get isGracePeriodActive => nextCheckIn != null && DateTime.now().isAfter(nextCheckIn!) && 
                                   (gracePeriodEnd == null || DateTime.now().isBefore(gracePeriodEnd!));
  bool get isTriggered => gracePeriodEnd != null && DateTime.now().isAfter(gracePeriodEnd!);
  bool get hasRequiredConfirmations => heirConfirmations
      .where((c) => c.confirmed)
      .length >= config.requiredConfirmations;
  
  DeadMansSwitchState copyWith({
    bool? isActive,
    DateTime? lastCheckIn,
    DateTime? lastNotification,
    int? missedCheckIns,
    DeadMansSwitchConfig? config,
    List<HeirConfirmation>? heirConfirmations,
  }) => DeadMansSwitchState(
    isActive: isActive ?? this.isActive,
    lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    lastNotification: lastNotification ?? this.lastNotification,
    missedCheckIns: missedCheckIns ?? this.missedCheckIns,
    config: config ?? this.config,
    heirConfirmations: heirConfirmations ?? this.heirConfirmations,
  );
  
  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'lastCheckIn': lastCheckIn?.toIso8601String(),
    'lastNotification': lastNotification?.toIso8601String(),
    'missedCheckIns': missedCheckIns,
    'config': config.toJson(),
    'heirConfirmations': heirConfirmations.map((c) => c.toJson()).toList(),
  };
  
  factory DeadMansSwitchState.fromJson(Map<String, dynamic> json) => DeadMansSwitchState(
    isActive: json['isActive'] as bool? ?? false,
    lastCheckIn: json['lastCheckIn'] != null ? DateTime.parse(json['lastCheckIn'] as String) : null,
    lastNotification: json['lastNotification'] != null ? DateTime.parse(json['lastNotification'] as String) : null,
    missedCheckIns: json['missedCheckIns'] as int? ?? 0,
    config: DeadMansSwitchConfig.fromJson(json['config'] as Map<String, dynamic>? ?? {}),
    heirConfirmations: (json['heirConfirmations'] as List<dynamic>?)
        ?.map((c) => HeirConfirmation.fromJson(c as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class HeirConfirmation {
  final String heirEmail;
  final bool confirmed;
  final DateTime? confirmedAt;
  final String confirmationToken;
  
  HeirConfirmation({
    required this.heirEmail,
    this.confirmed = false,
    this.confirmedAt,
    String? confirmationToken,
  }) : confirmationToken = confirmationToken ?? _generateToken();
  
  HeirConfirmation copyWith({
    bool? confirmed,
    DateTime? confirmedAt,
  }) => HeirConfirmation(
    heirEmail: heirEmail,
    confirmed: confirmed ?? this.confirmed,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    confirmationToken: confirmationToken,
  );
  
  Map<String, dynamic> toJson() => {
    'heirEmail': heirEmail,
    'confirmed': confirmed,
    'confirmedAt': confirmedAt?.toIso8601String(),
    'confirmationToken': confirmationToken,
  };
  
  factory HeirConfirmation.fromJson(Map<String, dynamic> json) => HeirConfirmation(
    heirEmail: json['heirEmail'] as String,
    confirmed: json['confirmed'] as bool? ?? false,
    confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt'] as String) : null,
    confirmationToken: json['confirmationToken'] as String,
  );
  
  static String _generateToken() {
    final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes);
  }
}

class DeadMansSwitchService {
  DeadMansSwitchService._();
  static final DeadMansSwitchService _instance = DeadMansSwitchService._();
  factory DeadMansSwitchService() => _instance;
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  static const _stateKey = 'dead_mans_switch_state';
  static const _configKey = 'dead_mans_switch_config';
  static const _heartbeatKey = 'dead_mans_switch_heartbeat';
  
  Timer? _heartbeatTimer;
  Timer? _monitorTimer;
  final SecurityService _security = SecurityService();
  
  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    try {
      await _loadState();
      _startHeartbeat();
      _startMonitoring();
      AppLogger.info('Dead Man\'s Switch service initialized');
    } catch (e, st) {
      AppLogger.error('Failed to initialize Dead Man\'s Switch', e, st);
    }
  }
  
  /// Activate the Dead Man's Switch with configuration
  Future<void> activate(DeadMansSwitchConfig config) async {
    try {
      // Validate configuration
      if (config.heirEmails.isEmpty) {
        throw ArgumentError('At least one heir email is required');
      }
      
      if (config.requiredConfirmations > config.heirEmails.length) {
        throw ArgumentError('Required confirmations cannot exceed number of heirs');
      }
      
      // Validate email formats
      for (final email in config.heirEmails) {
        if (!_security.isValidEmail(email)) {
          throw ArgumentError('Invalid email format: $email');
        }
      }
      
      final now = DateTime.now();
      final state = DeadMansSwitchState(
        isActive: true,
        lastCheckIn: now,
        config: config,
        heirConfirmations: config.heirEmails
            .map((email) => HeirConfirmation(heirEmail: email))
            .toList(),
      );
      
      await _saveState(state);
      await _saveConfig(config);
      
      // Log activation
      await _security.logSecurityEvent(
        'dead_mans_switch_activated',
        metadata: {
          'intervalDays': config.intervalDays,
          'heirCount': config.heirEmails.length,
          'requiredConfirmations': config.requiredConfirmations,
        },
      );
      
      AppLogger.info('Dead Man\'s Switch activated');
    } catch (e, st) {
      AppLogger.error('Failed to activate Dead Man\'s Switch', e, st);
      rethrow;
    }
  }
  
  /// Deactivate the Dead Man's Switch
  Future<void> deactivate() async {
    try {
      final state = await _loadState();
      if (state.isActive) {
        final deactivatedState = state.copyWith(isActive: false);
        await _saveState(deactivatedState);
        
        await _security.logSecurityEvent('dead_mans_switch_deactivated');
        AppLogger.info('Dead Man\'s Switch deactivated');
      }
    } catch (e, st) {
      AppLogger.error('Failed to deactivate Dead Man\'s Switch', e, st);
    }
  }
  
  /// Perform a check-in (heartbeat)
  Future<void> checkIn() async {
    try {
      final state = await _loadState();
      if (!state.isActive) return;
      
      final now = DateTime.now();
      final updatedState = state.copyWith(
        lastCheckIn: now,
        missedCheckIns: 0,
      );
      
      await _saveState(updatedState);
      await _storage.write(key: _heartbeatKey, value: now.toIso8601String());
      
      await _security.logSecurityEvent('dead_mans_switch_checkin');
      AppLogger.info('Dead Man\'s Switch check-in completed');
    } catch (e, st) {
      AppLogger.error('Failed to check-in', e, st);
    }
  }
  
  /// Get current state
  Future<DeadMansSwitchState> getState() async {
    return await _loadState();
  }
  
  /// Update configuration
  Future<void> updateConfig(DeadMansSwitchConfig config) async {
    try {
      final state = await _loadState();
      final updatedState = state.copyWith(config: config);
      await _saveState(updatedState);
      await _saveConfig(config);
      
      await _security.logSecurityEvent('dead_mans_switch_config_updated');
      AppLogger.info('Dead Man\'s Switch configuration updated');
    } catch (e, st) {
      AppLogger.error('Failed to update configuration', e, st);
    }
  }
  
  /// Confirm heir access
  Future<bool> confirmHeirAccess(String email, String token) async {
    try {
      final state = await _loadState();
      
      // Find heir confirmation
      final heirIndex = state.heirConfirmations
          .indexWhere((c) => c.heirEmail == email && c.confirmationToken == token);
      
      if (heirIndex == -1) {
        await _security.logSecurityEvent(
          'heir_confirmation_failed',
          metadata: {'email': email, 'reason': 'invalid_token'},
        );
        return false;
      }
      
      // Update confirmation
      final updatedConfirmations = List<HeirConfirmation>.from(state.heirConfirmations);
      updatedConfirmations[heirIndex] = updatedConfirmations[heirIndex].copyWith(
        confirmed: true,
        confirmedAt: DateTime.now(),
      );
      
      final updatedState = state.copyWith(heirConfirmations: updatedConfirmations);
      await _saveState(updatedState);
      
      await _security.logSecurityEvent(
        'heir_confirmed',
        metadata: {'email': email},
      );
      
      AppLogger.info('Heir confirmed: $email');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to confirm heir access', e, st);
      return false;
    }
  }
  
  /// Start periodic heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await _performHeartbeat();
      } catch (e, st) {
        AppLogger.error('Heartbeat failed', e, st);
      }
    });
  }
  
  /// Start monitoring for missed check-ins
  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(hours: 6), (_) async {
      try {
        await _monitorCheckIns();
      } catch (e, st) {
        AppLogger.error('Monitoring failed', e, st);
      }
    });
  }
  
  /// Perform automatic heartbeat
  Future<void> _performHeartbeat() async {
    final state = await _loadState();
    if (!state.isActive) return;
    
    final lastHeartbeat = await _storage.read(key: _heartbeatKey);
    if (lastHeartbeat != null) {
      final lastTime = DateTime.parse(lastHeartbeat);
      final now = DateTime.now();
      
      // If no heartbeat in 24 hours, perform automatic check-in
      if (now.difference(lastTime) > const Duration(hours: 24)) {
        await checkIn();
      }
    }
  }
  
  /// Monitor for missed check-ins and trigger notifications
  Future<void> _monitorCheckIns() async {
    final state = await _loadState();
    if (!state.isActive) return;
    
    final now = DateTime.now();
    final nextCheckIn = state.nextCheckIn;
    
    if (nextCheckIn != null) {
      // Check if we've passed the check-in time
      if (now.isAfter(nextCheckIn)) {
        if (state.lastNotification == null || 
            now.difference(state.lastNotification!) > const Duration(days: 1)) {
          await _sendNotifications(state);
        }
        
        // Check if grace period has ended
        if (state.isTriggered && !state.hasRequiredConfirmations) {
          await _triggerEmergencyProtocol(state);
        }
      }
    }
  }
  
  /// Send notifications to heirs
  Future<void> _sendNotifications(DeadMansSwitchState state) async {
    try {
      // Update notification timestamp
      final updatedState = state.copyWith(
        lastNotification: DateTime.now(),
        missedCheckIns: state.missedCheckIns + 1,
      );
      await _saveState(updatedState);
      
      // Send notifications via Firebase Cloud Messaging
      for (final heir in state.heirConfirmations) {
        await _sendNotificationToHeir(heir);
      }
      
      await _security.logSecurityEvent(
        'heir_notifications_sent',
        metadata: {
          'heirCount': state.heirConfirmations.length,
          'missedCheckIns': updatedState.missedCheckIns,
        },
      );
      
      AppLogger.info('Notifications sent to heirs');
    } catch (e, st) {
      AppLogger.error('Failed to send notifications', e, st);
    }
  }
  
  /// Send notification to specific heir
  Future<void> _sendNotificationToHeir(HeirConfirmation heir) async {
    try {
      // This would integrate with your notification service
      // For now, we'll just log the action
      AppLogger.info('Notification sent to heir: ${heir.heirEmail}');
      
      // In production, you would:
      // 1. Send email with confirmation link
      // 2. Send push notification via FCM
      // 3. Log the notification attempt
    } catch (e, st) {
      AppLogger.error('Failed to send notification to heir', e, st);
    }
  }
  
  /// Trigger emergency protocol when grace period ends
  Future<void> _triggerEmergencyProtocol(DeadMansSwitchState state) async {
    try {
      await _security.logSecurityEvent(
        'emergency_protocol_triggered',
        metadata: {
          'missedCheckIns': state.missedCheckIns,
          'confirmedHeirs': state.heirConfirmations.where((c) => c.confirmed).length,
        },
      );
      
      // This would implement your emergency protocol
      // Examples:
      // - Release encrypted documents to confirmed heirs
      // - Send emergency notifications
      // - Activate backup recovery procedures
      
      AppLogger.warning('Emergency protocol triggered - insufficient heir confirmations');
    } catch (e, st) {
      AppLogger.error('Failed to trigger emergency protocol', e, st);
    }
  }
  
  /// Load state from storage
  Future<DeadMansSwitchState> _loadState() async {
    try {
      final stateJson = await _storage.read(key: _stateKey);
      if (stateJson != null) {
        return DeadMansSwitchState.fromJson(jsonDecode(stateJson) as Map<String, dynamic>);
      }
    } catch (e, st) {
      AppLogger.error('Failed to load state', e, st);
    }
    return const DeadMansSwitchState();
  }
  
  /// Save state to storage
  Future<void> _saveState(DeadMansSwitchState state) async {
    try {
      await _storage.write(key: _stateKey, value: jsonEncode(state.toJson()));
    } catch (e, st) {
      AppLogger.error('Failed to save state', e, st);
    }
  }
  
  /// Save configuration to storage
  Future<void> _saveConfig(DeadMansSwitchConfig config) async {
    try {
      await _storage.write(key: _configKey, value: jsonEncode(config.toJson()));
    } catch (e, st) {
      AppLogger.error('Failed to save config', e, st);
    }
  }
  
  /// Dispose timers
  void dispose() {
    _heartbeatTimer?.cancel();
    _monitorTimer?.cancel();
  }
}
