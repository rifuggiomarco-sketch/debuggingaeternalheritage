// v3.0 - Enhanced Dead Man's Switch Service with Multi-channel Check-in and Grace Period
// Provides enterprise-grade heritage protocol with fail-safe mechanisms and redundancy
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';
import 'security_service.dart';
import 'advanced_security_logging_service.dart';

enum CheckInChannel {
  email,
  sms,
  push,
  in_app,
  webhook,
}

enum DeadMansSwitchStatus {
  inactive,
  active,
  check_in_pending,
  grace_period_active,
  triggered,
  canceled,
}

class CheckInConfig {
  final List<CheckInChannel> channels;
  final Duration interval;
  final int maxMissedCheckIns;
  final Duration gracePeriod;
  final bool requireMultipleChannels;
  final int requiredChannelConfirmations;
  
  const CheckInConfig({
    this.channels = const [CheckInChannel.email, CheckInChannel.in_app],
    this.interval = const Duration(days: 60),
    this.maxMissedCheckIns = 3,
    this.gracePeriod = const Duration(hours: 48),
    this.requireMultipleChannels = true,
    this.requiredChannelConfirmations = 2,
  });
  
  Map<String, dynamic> toJson() => {
    'channels': channels.map((c) => c.name).toList(),
    'interval': interval.inMilliseconds,
    'maxMissedCheckIns': maxMissedCheckIns,
    'gracePeriod': gracePeriod.inMilliseconds,
    'requireMultipleChannels': requireMultipleChannels,
    'requiredChannelConfirmations': requiredChannelConfirmations,
  };
  
  factory CheckInConfig.fromJson(Map<String, dynamic> json) => CheckInConfig(
    channels: (json['channels'] as List<dynamic>?)
        ?.map((c) => CheckInChannel.values.firstWhere((v) => v.name == c))
        .toList() ?? [CheckInChannel.email, CheckInChannel.in_app],
    interval: Duration(milliseconds: json['interval'] as int? ?? Duration(days: 60).inMilliseconds),
    maxMissedCheckIns: json['maxMissedCheckIns'] as int? ?? 3,
    gracePeriod: Duration(milliseconds: json['gracePeriod'] as int? ?? Duration(hours: 48).inMilliseconds),
    requireMultipleChannels: json['requireMultipleChannels'] as bool? ?? true,
    requiredChannelConfirmations: json['requiredChannelConfirmations'] as int? ?? 2,
  );
}

class HeirConfig {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> deviceTokens;
  final List<String> allowedFolders;
  final bool canReceiveAll;
  final DateTime? lastNotified;
  final String? lastNotificationChannel;
  
  HeirConfig({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.deviceTokens = const [],
    this.allowedFolders = const [],
    this.canReceiveAll = false,
    this.lastNotified,
    this.lastNotificationChannel,
  });
  
  HeirConfig copyWith({
    String? name,
    String? email,
    String? phone,
    List<String>? deviceTokens,
    List<String>? allowedFolders,
    bool? canReceiveAll,
    DateTime? lastNotified,
    String? lastNotificationChannel,
  }) => HeirConfig(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    deviceTokens: deviceTokens ?? this.deviceTokens,
    allowedFolders: allowedFolders ?? this.allowedFolders,
    canReceiveAll: canReceiveAll ?? this.canReceiveAll,
    lastNotified: lastNotified ?? this.lastNotified,
    lastNotificationChannel: lastNotificationChannel ?? this.lastNotificationChannel,
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'deviceTokens': deviceTokens,
    'allowedFolders': allowedFolders,
    'canReceiveAll': canReceiveAll,
    'lastNotified': lastNotified?.toIso8601String(),
    'lastNotificationChannel': lastNotificationChannel,
  };
  
  factory HeirConfig.fromJson(Map<String, dynamic> json) => HeirConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    deviceTokens: (json['deviceTokens'] as List<dynamic>?)?.cast<String>() ?? [],
    allowedFolders: (json['allowedFolders'] as List<dynamic>?)?.cast<String>() ?? [],
    canReceiveAll: json['canReceiveAll'] as bool? ?? false,
    lastNotified: json['lastNotified'] != null ? DateTime.parse(json['lastNotified'] as String) : null,
    lastNotificationChannel: json['lastNotificationChannel'] as String?,
  );
}

class CheckInRecord {
  final String id;
  final CheckInChannel channel;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;
  final String? responseCode;
  
  CheckInRecord({
    required this.id,
    required this.channel,
    required this.timestamp,
    required this.success,
    this.errorMessage,
    this.responseCode,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'channel': channel.name,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'errorMessage': errorMessage,
    'responseCode': responseCode,
  };
  
  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    id: json['id'] as String,
    channel: CheckInChannel.values.firstWhere((c) => c.name == json['channel']),
    timestamp: DateTime.parse(json['timestamp'] as String),
    success: json['success'] as bool,
    errorMessage: json['errorMessage'] as String?,
    responseCode: json['responseCode'] as String?,
  );
}

class EnhancedDeadMansSwitchState {
  final DeadMansSwitchStatus status;
  final CheckInConfig config;
  final List<HeirConfig> heirs;
  final List<CheckInRecord> checkInHistory;
  final DateTime? lastCheckIn;
  final DateTime? gracePeriodStart;
  final DateTime? gracePeriodEnd;
  final DateTime? triggeredAt;
  final Map<String, String> heirConfirmations;
  final Map<String, DateTime> channelLastUsed;
  
  const EnhancedDeadMansSwitchState({
    this.status = DeadMansSwitchStatus.inactive,
    this.config = const CheckInConfig(),
    this.heirs = const [],
    this.checkInHistory = const [],
    this.lastCheckIn,
    this.gracePeriodStart,
    this.gracePeriodEnd,
    this.triggeredAt,
    this.heirConfirmations = const {},
    this.channelLastUsed = const {},
  });
  
  DateTime? get nextCheckInDeadline => lastCheckIn?.add(config.interval);
  bool get isCheckInOverdue => nextCheckInDeadline != null && DateTime.now().isAfter(nextCheckInDeadline!);
  bool get isInGracePeriod => status == DeadMansSwitchStatus.grace_period_active && 
                               gracePeriodStart != null && 
                               gracePeriodEnd != null && 
                               DateTime.now().isBefore(gracePeriodEnd!);
  bool get isGracePeriodExpired => gracePeriodEnd != null && DateTime.now().isAfter(gracePeriodEnd!);
  int get missedCheckIns => checkInHistory.where((record) => !record.success).length;
  bool get hasEnoughConfirmations => heirConfirmations.length >= config.requiredChannelConfirmations;
  
  EnhancedDeadMansSwitchState copyWith({
    DeadMansSwitchStatus? status,
    CheckInConfig? config,
    List<HeirConfig>? heirs,
    List<CheckInRecord>? checkInHistory,
    DateTime? lastCheckIn,
    DateTime? gracePeriodStart,
    DateTime? gracePeriodEnd,
    DateTime? triggeredAt,
    Map<String, String>? heirConfirmations,
    Map<String, DateTime>? channelLastUsed,
  }) => EnhancedDeadMansSwitchState(
    status: status ?? this.status,
    config: config ?? this.config,
    heirs: heirs ?? this.heirs,
    checkInHistory: checkInHistory ?? this.checkInHistory,
    lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    gracePeriodStart: gracePeriodStart ?? this.gracePeriodStart,
    gracePeriodEnd: gracePeriodEnd ?? this.gracePeriodEnd,
    triggeredAt: triggeredAt ?? this.triggeredAt,
    heirConfirmations: heirConfirmations ?? this.heirConfirmations,
    channelLastUsed: channelLastUsed ?? this.channelLastUsed,
  );
  
  Map<String, dynamic> toJson() => {
    'status': status.name,
    'config': config.toJson(),
    'heirs': heirs.map((h) => h.toJson()).toList(),
    'checkInHistory': checkInHistory.map((c) => c.toJson()).toList(),
    'lastCheckIn': lastCheckIn?.toIso8601String(),
    'gracePeriodStart': gracePeriodStart?.toIso8601String(),
    'gracePeriodEnd': gracePeriodEnd?.toIso8601String(),
    'triggeredAt': triggeredAt?.toIso8601String(),
    'heirConfirmations': heirConfirmations,
    'channelLastUsed': channelLastUsed.map((k, v) => MapEntry(k, v.toIso8601String())),
  };
  
  factory EnhancedDeadMansSwitchState.fromJson(Map<String, dynamic> json) => EnhancedDeadMansSwitchState(
    status: DeadMansSwitchStatus.values.firstWhere((s) => s.name == json['status']),
    config: CheckInConfig.fromJson(json['config'] as Map<String, dynamic>),
    heirs: (json['heirs'] as List<dynamic>?)
        ?.map((h) => HeirConfig.fromJson(h as Map<String, dynamic>))
        .toList() ?? [],
    checkInHistory: (json['checkInHistory'] as List<dynamic>?)
        ?.map((c) => CheckInRecord.fromJson(c as Map<String, dynamic>))
        .toList() ?? [],
    lastCheckIn: json['lastCheckIn'] != null ? DateTime.parse(json['lastCheckIn'] as String) : null,
    gracePeriodStart: json['gracePeriodStart'] != null ? DateTime.parse(json['gracePeriodStart'] as String) : null,
    gracePeriodEnd: json['gracePeriodEnd'] != null ? DateTime.parse(json['gracePeriodEnd'] as String) : null,
    triggeredAt: json['triggeredAt'] != null ? DateTime.parse(json['triggeredAt'] as String) : null,
    heirConfirmations: (json['heirConfirmations'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
    channelLastUsed: (json['channelLastUsed'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, DateTime.parse(v as String))) ?? {},
  );
}

class EnhancedDeadMansSwitchService {
  EnhancedDeadMansSwitchService._();
  static final EnhancedDeadMansSwitchService _instance = EnhancedDeadMansSwitchService._();
  factory EnhancedDeadMansSwitchService() => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _stateKey = 'enhanced_dead_mans_switch_state_v3';
  static const _heartbeatKey = 'enhanced_dead_mans_switch_heartbeat';
  static const _configKey = 'enhanced_dead_mans_switch_config';

  Timer? _heartbeatTimer;
  Timer? _monitorTimer;
  Timer? _gracePeriodTimer;
  
  final SecurityService _security = SecurityService();
  final AdvancedSecurityLoggingService _logging = AdvancedSecurityLoggingService();
  
  String? _emailServiceEndpoint;
  String? _smsServiceEndpoint;
  String? _pushServiceEndpoint;

  /// Initialize the enhanced service
  Future<void> initialize({
    String? emailServiceEndpoint,
    String? smsServiceEndpoint,
    String? pushServiceEndpoint,
  }) async {
    try {
      _emailServiceEndpoint = emailServiceEndpoint;
      _smsServiceEndpoint = smsServiceEndpoint;
      _pushServiceEndpoint = pushServiceEndpoint;
      
      await _loadState();
      await _startHeartbeat();
      await _startMonitoring();
      
      AppLogger.info('Enhanced Dead Man\'s Switch service initialized');
    } catch (e, st) {
      AppLogger.error('Failed to initialize enhanced Dead Man\'s Switch', e, st);
    }
  }

  /// Activate the enhanced Dead Man's Switch
  Future<void> activate({
    required CheckInConfig config,
    required List<HeirConfig> heirs,
  }) async {
    try {
      // Validate configuration
      _validateConfig(config, heirs);
      
      final now = DateTime.now();
      final state = EnhancedDeadMansSwitchState(
        status: DeadMansSwitchStatus.active,
        config: config,
        heirs: heirs,
        lastCheckIn: now,
        checkInHistory: [
          CheckInRecord(
            id: _generateId(),
            channel: CheckInChannel.in_app,
            timestamp: now,
            success: true,
          ),
        ],
      );
      
      await _saveState(state);
      
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user', // Replace with actual user ID
        action: 'activated',
        metadata: {
          'config': config.toJson(),
          'heirCount': heirs.length,
          'channels': config.channels.map((c) => c.name).toList(),
        },
      );
      
      AppLogger.info('Enhanced Dead Man\'s Switch activated');
    } catch (e, st) {
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'activation_failed',
        success: false,
        metadata: {'error': e.toString()},
      );
      AppLogger.error('Failed to activate Dead Man\'s Switch', e, st);
      rethrow;
    }
  }

  /// Perform multi-channel check-in
  Future<Map<CheckInChannel, bool>> performCheckIn({
    List<CheckInChannel>? channels,
  }) async {
    try {
      final state = await _loadState();
      if (state.status != DeadMansSwitchStatus.active) {
        throw StateError('Dead Man\'s Switch is not active');
      }
      
      final channelsToUse = channels ?? state.config.channels;
      final results = <CheckInChannel, bool>{};
      final now = DateTime.now();
      
      for (final channel in channelsToUse) {
        try {
          final success = await _performChannelCheckIn(channel);
          results[channel] = success;
          
          final record = CheckInRecord(
            id: _generateId(),
            channel: channel,
            timestamp: now,
            success: success,
          );
          
          // Update state
          final updatedHistory = [...state.checkInHistory, record];
          final updatedChannelLastUsed = Map<String, DateTime>.from(state.channelLastUsed);
          updatedChannelLastUsed[channel.name] = now;
          
          // If successful and enough channels confirmed, update last check-in
          DateTime? newLastCheckIn = state.lastCheckIn;
          if (success && _hasEnoughSuccessfulChannels(updatedHistory, state.config)) {
            newLastCheckIn = now;
          }
          
          final updatedState = state.copyWith(
            checkInHistory: updatedHistory,
            channelLastUsed: updatedChannelLastUsed,
            lastCheckIn: newLastCheckIn,
          );
          
          await _saveState(updatedState);
          
        } catch (e, st) {
          results[channel] = false;
          AppLogger.error('Channel check-in failed for $channel', e, st);
        }
      }
      
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'check_in_completed',
        metadata: {
          'channels': results.map((k, v) => MapEntry(k.name, v)),
          'successRate': results.values.where((v) => v).length / results.length,
        },
      );
      
      return results;
    } catch (e, st) {
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'check_in_failed',
        success: false,
        metadata: {'error': e.toString()},
      );
      AppLogger.error('Failed to perform check-in', e, st);
      rethrow;
    }
  }

  /// Cancel grace period (user intervention)
  Future<void> cancelGracePeriod() async {
    try {
      final state = await _loadState();
      if (state.status != DeadMansSwitchStatus.grace_period_active) {
        throw StateError('No active grace period to cancel');
      }
      
      final updatedState = state.copyWith(
        status: DeadMansSwitchStatus.active,
        gracePeriodStart: null,
        gracePeriodEnd: null,
        lastCheckIn: DateTime.now(),
      );
      
      await _saveState(updatedState);
      
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'grace_period_canceled',
        metadata: {
          'gracePeriodStart': state.gracePeriodStart?.toIso8601String(),
          'gracePeriodEnd': state.gracePeriodEnd?.toIso8601String(),
        },
      );
      
      AppLogger.info('Grace period canceled - service reactivated');
    } catch (e, st) {
      AppLogger.error('Failed to cancel grace period', e, st);
      rethrow;
    }
  }

  /// Confirm heir access with conditional inheritance
  Future<bool> confirmHeirAccess({
    required String heirId,
    required String token,
    Map<String, dynamic>? accessRequest,
  }) async {
    try {
      final state = await _loadState();
      
      // Find heir
      final heir = state.heirs.where((h) => h.id == heirId).firstOrNull;
      if (heir == null) {
        throw ArgumentError('Heir not found');
      }
      
      // Validate token (simplified - in production, use proper cryptographic verification)
      if (!_validateHeirToken(heir, token)) {
        await _logging.logDeadMansSwitchEvent(
          userId: 'current_user',
          action: 'heir_confirmation_failed',
          success: false,
          metadata: {
            'heirId': heirId,
            'reason': 'invalid_token',
          },
        );
        return false;
      }
      
      // Check conditional inheritance
      if (!_validateHeirAccess(heir, accessRequest)) {
        await _logging.logDeadMansSwitchEvent(
          userId: 'current_user',
          action: 'heir_confirmation_failed',
          success: false,
          metadata: {
            'heirId': heirId,
            'reason': 'access_denied_conditional',
          },
        );
        return false;
      }
      
      // Update state
      final updatedConfirmations = Map<String, String>.from(state.heirConfirmations);
      updatedConfirmations[heirId] = token;
      
      final updatedState = state.copyWith(heirConfirmations: updatedConfirmations);
      await _saveState(updatedState);
      
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'heir_confirmed',
        metadata: {
          'heirId': heirId,
          'heirName': heir.name,
          'accessLevel': heir.canReceiveAll ? 'full' : 'conditional',
        },
      );
      
      AppLogger.info('Heir access confirmed: ${heir.name}');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to confirm heir access', e, st);
      return false;
    }
  }

  /// Get current state
  Future<EnhancedDeadMansSwitchState> getState() async {
    return await _loadState();
  }

  /// Get heir access permissions
  Future<Map<String, dynamic>> getHeirAccessPermissions(String heirId) async {
    try {
      final state = await _loadState();
      final heir = state.heirs.where((h) => h.id == heirId).firstOrNull;
      
      if (heir == null) {
        throw ArgumentError('Heir not found');
      }
      
      return {
        'heirId': heir.id,
        'name': heir.name,
        'email': heir.email,
        'canReceiveAll': heir.canReceiveAll,
        'allowedFolders': heir.allowedFolders,
        'confirmed': state.heirConfirmations.containsKey(heirId),
        'accessLevel': heir.canReceiveAll ? 'full' : 'conditional',
      };
    } catch (e, st) {
      AppLogger.error('Failed to get heir access permissions', e, st);
      rethrow;
    }
  }

  /// Private methods

  void _validateConfig(CheckInConfig config, List<HeirConfig> heirs) {
    if (heirs.isEmpty) {
      throw ArgumentError('At least one heir must be specified');
    }
    
    if (config.channels.isEmpty) {
      throw ArgumentError('At least one check-in channel must be specified');
    }
    
    if (config.requiredChannelConfirmations > config.channels.length) {
      throw ArgumentError('Required channel confirmations cannot exceed available channels');
    }
    
    if (config.requiredChannelConfirmations > heirs.length) {
      throw ArgumentError('Required channel confirmations cannot exceed number of heirs');
    }
    
    // Validate heir configurations
    for (final heir in heirs) {
      if (!_security.isValidEmail(heir.email)) {
        throw ArgumentError('Invalid email format for heir: ${heir.email}');
      }
      
      if (heir.phone != null && heir.phone!.isEmpty) {
        throw ArgumentError('Phone number cannot be empty if specified');
      }
    }
  }

  Future<bool> _performChannelCheckIn(CheckInChannel channel) async {
    switch (channel) {
      case CheckInChannel.in_app:
        return await _performInAppCheckIn();
      case CheckInChannel.email:
        return await _performEmailCheckIn();
      case CheckInChannel.sms:
        return await _performSmsCheckIn();
      case CheckInChannel.push:
        return await _performPushCheckIn();
      case CheckInChannel.webhook:
        return await _performWebhookCheckIn();
    }
  }

  Future<bool> _performInAppCheckIn() async {
    // In-app check-in is always successful when called
    return true;
  }

  Future<bool> _performEmailCheckIn() async {
    if (_emailServiceEndpoint == null) {
      AppLogger.warning('Email service endpoint not configured');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_emailServiceEndpoint/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 'current_user',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'dead_mans_switch_checkin',
        }),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e, st) {
      AppLogger.error('Email check-in failed', e, st);
      return false;
    }
  }

  Future<bool> _performSmsCheckIn() async {
    if (_smsServiceEndpoint == null) {
      AppLogger.warning('SMS service endpoint not configured');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_smsServiceEndpoint/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 'current_user',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'dead_mans_switch_checkin',
        }),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e, st) {
      AppLogger.error('SMS check-in failed', e, st);
      return false;
    }
  }

  Future<bool> _performPushCheckIn() async {
    if (_pushServiceEndpoint == null) {
      AppLogger.warning('Push service endpoint not configured');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_pushServiceEndpoint/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 'current_user',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'dead_mans_switch_checkin',
        }),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e, st) {
      AppLogger.error('Push check-in failed', e, st);
      return false;
    }
  }

  Future<bool> _performWebhookCheckIn() async {
    // Webhook check-in would be implemented based on user configuration
    // For now, return true as placeholder
    return true;
  }

  bool _hasEnoughSuccessfulChannels(List<CheckInRecord> history, CheckInConfig config) {
    if (!config.requireMultipleChannels) return true;
    
    final recentHistory = history.where((record) => 
        DateTime.now().difference(record.timestamp) <= const Duration(hours: 24));
    
    final successfulChannels = <CheckInChannel>{};
    for (final record in recentHistory) {
      if (record.success) {
        successfulChannels.add(record.channel);
      }
    }
    
    return successfulChannels.length >= config.requiredChannelConfirmations;
  }

  bool _validateHeirToken(HeirConfig heir, String token) {
    // In production, implement proper cryptographic token validation
    // For now, simple length check as placeholder
    return token.isNotEmpty && token.length >= 20;
  }

  bool _validateHeirAccess(HeirConfig heir, Map<String, dynamic>? accessRequest) {
    // Check conditional inheritance rules
    if (heir.canReceiveAll) return true;
    
    // If specific folders are allowed, check if request is for allowed folders
    if (heir.allowedFolders.isNotEmpty && accessRequest != null) {
      final requestedFolders = accessRequest['folders'] as List<String>? ?? [];
      return requestedFolders.every((folder) => heir.allowedFolders.contains(folder));
    }
    
    return false;
  }

  Future<void> _startHeartbeat() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await _performAutomaticHeartbeat();
      } catch (e, st) {
        AppLogger.error('Automatic heartbeat failed', e, st);
      }
    });
  }

  Future<void> _startMonitoring() async {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(hours: 6), (_) async {
      try {
        await _monitorDeadMansSwitch();
      } catch (e, st) {
        AppLogger.error('Dead Man\'s Switch monitoring failed', e, st);
      }
    });
  }

  Future<void> _performAutomaticHeartbeat() async {
    try {
      final state = await _loadState();
      if (state.status != DeadMansSwitchStatus.active) return;
      
      // Perform in-app check-in automatically
      await performCheckIn(channels: [CheckInChannel.in_app]);
    } catch (e, st) {
      AppLogger.error('Automatic heartbeat failed', e, st);
    }
  }

  Future<void> _monitorDeadMansSwitch() async {
    try {
      final state = await _loadState();
      
      if (state.status == DeadMansSwitchStatus.active && state.isCheckInOverdue) {
        await _handleMissedCheckIn(state);
      } else if (state.status == DeadMansSwitchStatus.grace_period_active && state.isGracePeriodExpired) {
        await _triggerDeadMansSwitch(state);
      }
    } catch (e, st) {
      AppLogger.error('Dead Man\'s Switch monitoring failed', e, st);
    }
  }

  Future<void> _handleMissedCheckIn(EnhancedDeadMansSwitchState state) async {
    try {
      final missedCount = state.missedCheckIns + 1;
      
      if (missedCount >= state.config.maxMissedCheckIns) {
        // Start grace period
        final now = DateTime.now();
        final graceEnd = now.add(state.config.gracePeriod);
        
        final updatedState = state.copyWith(
          status: DeadMansSwitchStatus.grace_period_active,
          gracePeriodStart: now,
          gracePeriodEnd: graceEnd,
        );
        
        await _saveState(updatedState);
        await _startGracePeriodTimer();
        await _notifyHeirsOfGracePeriod(updatedState);
        
        await _logging.logDeadMansSwitchEvent(
          userId: 'current_user',
          action: 'grace_period_started',
          metadata: {
            'gracePeriodStart': now.toIso8601String(),
            'gracePeriodEnd': graceEnd.toIso8601String(),
            'missedCheckIns': missedCount,
          },
        );
        
        AppLogger.warning('Grace period started - user has ${state.config.gracePeriod.inHours} hours to respond');
      } else {
        // Send warning notifications
        await _sendWarningNotifications(state, missedCount);
        
        await _logging.logDeadMansSwitchEvent(
          userId: 'current_user',
          action: 'missed_check_in_warning',
          metadata: {
            'missedCount': missedCount,
            'maxMissed': state.config.maxMissedCheckIns,
          },
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to handle missed check-in', e, st);
    }
  }

  Future<void> _triggerDeadMansSwitch(EnhancedDeadMansSwitchState state) async {
    try {
      final updatedState = state.copyWith(
        status: DeadMansSwitchStatus.triggered,
        triggeredAt: DateTime.now(),
      );
      
      await _saveState(updatedState);
      await _executeEmergencyProtocol(updatedState);
      
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'triggered',
        metadata: {
          'triggeredAt': DateTime.now().toIso8601String(),
          'confirmedHeirs': state.heirConfirmations.length,
          'totalHeirs': state.heirs.length,
        },
      );
      
      AppLogger.critical('Dead Man\'s Switch triggered - emergency protocol executed');
    } catch (e, st) {
      AppLogger.error('Failed to trigger Dead Man\'s Switch', e, st);
    }
  }

  Future<void> _startGracePeriodTimer() async {
    _gracePeriodTimer?.cancel();
    
    final state = await _loadState();
    if (state.gracePeriodEnd != null) {
      final duration = state.gracePeriodEnd!.difference(DateTime.now());
      if (duration.inMilliseconds > 0) {
        _gracePeriodTimer = Timer(duration, () async {
          await _triggerDeadMansSwitch(state);
        });
      }
    }
  }

  Future<void> _notifyHeirsOfGracePeriod(EnhancedDeadMansSwitchState state) async {
    for (final heir in state.heirs) {
      try {
        await _sendNotificationToHeir(heir, 'grace_period_started', {
          'gracePeriodEnd': state.gracePeriodEnd?.toIso8601String(),
          'message': 'The Dead Man\'s Switch grace period has started. Please be prepared to confirm access if needed.',
        });
      } catch (e, st) {
        AppLogger.error('Failed to notify heir ${heir.name} of grace period', e, st);
      }
    }
  }

  Future<void> _sendWarningNotifications(EnhancedDeadMansSwitchState state, int missedCount) async {
    for (final heir in state.heirs) {
      try {
        await _sendNotificationToHeir(heir, 'missed_check_in_warning', {
          'missedCount': missedCount,
          'maxMissed': state.config.maxMissedCheckIns,
          'message': 'Warning: $missedCount of ${state.config.maxMissedCheckIns} check-ins missed.',
        });
      } catch (e, st) {
        AppLogger.error('Failed to send warning to heir ${heir.name}', e, st);
      }
    }
  }

  Future<void> _sendNotificationToHeir(HeirConfig heir, String type, Map<String, dynamic> data) async {
    // Update heir's last notification
    final state = await _loadState();
    final updatedHeirs = state.heirs.map((h) {
      if (h.id == heir.id) {
        return h.copyWith(
          lastNotified: DateTime.now(),
          lastNotificationChannel: type,
        );
      }
      return h;
    }).toList();
    
    final updatedState = state.copyWith(heirs: updatedHeirs);
    await _saveState(updatedState);
    
    // Send notification via available channels
    if (_emailServiceEndpoint != null) {
      await _sendEmailNotification(heir, type, data);
    }
    
    if (_smsServiceEndpoint != null && heir.phone != null) {
      await _sendSmsNotification(heir, type, data);
    }
    
    if (_pushServiceEndpoint != null && heir.deviceTokens.isNotEmpty) {
      await _sendPushNotification(heir, type, data);
    }
  }

  Future<void> _sendEmailNotification(HeirConfig heir, String type, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_emailServiceEndpoint/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': heir.email,
          'type': type,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('Email notification failed: ${response.statusCode}');
      }
    } catch (e, st) {
      AppLogger.error('Failed to send email notification to ${heir.email}', e, st);
    }
  }

  Future<void> _sendSmsNotification(HeirConfig heir, String type, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_smsServiceEndpoint/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': heir.phone,
          'type': type,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('SMS notification failed: ${response.statusCode}');
      }
    } catch (e, st) {
      AppLogger.error('Failed to send SMS notification to ${heir.phone}', e, st);
    }
  }

  Future<void> _sendPushNotification(HeirConfig heir, String type, Map<String, dynamic> data) async {
    try {
      for (final token in heir.deviceTokens) {
        final response = await http.post(
          Uri.parse('$_pushServiceEndpoint/send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': token,
            'type': type,
            'data': data,
          }),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode != 200) {
          throw Exception('Push notification failed: ${response.statusCode}');
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to send push notification to ${heir.name}', e, st);
    }
  }

  Future<void> _executeEmergencyProtocol(EnhancedDeadMansSwitchState state) async {
    try {
      // This would implement the emergency protocol
      // Examples:
      // - Release encrypted documents to confirmed heirs
      // - Send emergency notifications
      // - Activate backup recovery procedures
      
      for (final heirId in state.heirConfirmations.keys) {
        final heir = state.heirs.where((h) => h.id == heirId).firstOrNull;
        if (heir != null) {
          await _grantAccessToHeir(heir);
        }
      }
      
      AppLogger.critical('Emergency protocol executed for ${state.heirConfirmations.length} heirs');
    } catch (e, st) {
      AppLogger.error('Failed to execute emergency protocol', e, st);
    }
  }

  Future<void> _grantAccessToHeir(HeirConfig heir) async {
    try {
      await _logging.logDeadMansSwitchEvent(
        userId: 'current_user',
        action: 'access_granted_to_heir',
        metadata: {
          'heirId': heir.id,
          'heirName': heir.name,
          'accessLevel': heir.canReceiveAll ? 'full' : 'conditional',
          'allowedFolders': heir.allowedFolders,
        },
      );
      
      AppLogger.info('Access granted to heir: ${heir.name}');
    } catch (e, st) {
      AppLogger.error('Failed to grant access to heir ${heir.name}', e, st);
    }
  }

  Future<EnhancedDeadMansSwitchState> _loadState() async {
    try {
      final stateJson = await _storage.read(key: _stateKey);
      if (stateJson != null) {
        return EnhancedDeadMansSwitchState.fromJson(jsonDecode(stateJson) as Map<String, dynamic>);
      }
    } catch (e, st) {
      AppLogger.error('Failed to load Dead Man\'s Switch state', e, st);
    }
    return const EnhancedDeadMansSwitchState();
  }

  Future<void> _saveState(EnhancedDeadMansSwitchState state) async {
    try {
      await _storage.write(key: _stateKey, value: jsonEncode(state.toJson()));
    } catch (e, st) {
      AppLogger.error('Failed to save Dead Man\'s Switch state', e, st);
    }
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(10000);
    return 'dms_${timestamp}_$random';
  }

  /// Dispose resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _monitorTimer?.cancel();
    _gracePeriodTimer?.cancel();
  }
}
