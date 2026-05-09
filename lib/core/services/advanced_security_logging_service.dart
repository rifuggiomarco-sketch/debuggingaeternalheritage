// v3.0 - Advanced Security Logging Service
// Comprehensive security audit logging with offline resilience and forensic capabilities
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';

enum SecurityLogLevel {
  info,
  warning,
  critical,
  forensic,
}

enum SecurityLogCategory {
  authentication,
  authorization,
  data_access,
  configuration_change,
  system_event,
  security_violation,
  business_event,
  compliance,
}

class SecurityLogEntry {
  final String id;
  final SecurityLogLevel level;
  final SecurityLogCategory category;
  final String event;
  final String? userId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata;
  final bool? success;
  final String? errorMessage;
  final String? stackTrace;
  final String sessionId;
  
  SecurityLogEntry({
    required this.id,
    required this.level,
    required this.category,
    required this.event,
    this.userId,
    DateTime? timestamp,
    this.ipAddress,
    this.userAgent,
    this.metadata,
    this.success,
    this.errorMessage,
    this.stackTrace,
    String? sessionId,
  }) : timestamp = timestamp ?? DateTime.now(),
       sessionId = sessionId ?? _generateSessionId();

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level.name,
    'category': category.name,
    'event': event,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'metadata': metadata,
    'success': success,
    'errorMessage': errorMessage,
    'stackTrace': stackTrace,
    'sessionId': sessionId,
  };

  factory SecurityLogEntry.fromJson(Map<String, dynamic> json) => SecurityLogEntry(
    id: json['id'] as String,
    level: SecurityLogLevel.values.firstWhere((l) => l.name == json['level']),
    category: SecurityLogCategory.values.firstWhere((c) => c.name == json['category']),
    event: json['event'] as String,
    userId: json['userId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    ipAddress: json['ipAddress'] as String?,
    userAgent: json['userAgent'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    success: json['success'] as bool?,
    errorMessage: json['errorMessage'] as String?,
    stackTrace: json['stackTrace'] as String?,
    sessionId: json['sessionId'] as String?,
  );

  static String _generateSessionId() {
    final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
    return base64Encode(bytes);
  }
}

class SecurityLogFilter {
  final SecurityLogLevel? minLevel;
  final SecurityLogCategory? category;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? success;
  final String? sessionId;

  SecurityLogFilter({
    this.minLevel,
    this.category,
    this.userId,
    this.startDate,
    this.endDate,
    this.success,
    this.sessionId,
  });

  bool matches(SecurityLogEntry entry) {
    if (minLevel != null && entry.level.index < minLevel!.index) return false;
    if (category != null && entry.category != category) return false;
    if (userId != null && entry.userId != userId) return false;
    if (startDate != null && entry.timestamp.isBefore(startDate!)) return false;
    if (endDate != null && entry.timestamp.isAfter(endDate!)) return false;
    if (success != null && entry.success != success) return false;
    if (sessionId != null && entry.sessionId != sessionId) return false;
    return true;
  }
}

class AdvancedSecurityLoggingService {
  AdvancedSecurityLoggingService._();
  static final AdvancedSecurityLoggingService _instance = AdvancedSecurityLoggingService._();
  factory AdvancedSecurityLoggingService() => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _logKey = 'security_log_v3';
  static const _bufferKey = 'security_log_buffer';
  static const _configKey = 'security_log_config';
  static const _maxLogSize = 10000;
  static const _bufferSize = 100;
  static const _syncInterval = Duration(minutes: 5);

  Timer? _syncTimer;
  bool _isOnline = true;
  String? _serverEndpoint;
  Map<String, dynamic>? _config;

  /// Initialize the advanced logging service
  Future<void> initialize({String? serverEndpoint}) async {
    try {
      _serverEndpoint = serverEndpoint;
      await _loadConfiguration();
      await _startSyncTimer();
      await _checkConnectivity();
      
      AppLogger.info('Advanced Security Logging Service initialized');
    } catch (e, st) {
      AppLogger.error('Failed to initialize advanced logging service', e, st);
    }
  }

  /// Log a security event with comprehensive context
  Future<void> logSecurityEvent({
    required SecurityLogLevel level,
    required SecurityLogCategory category,
    required String event,
    String? userId,
    Map<String, dynamic>? metadata,
    bool? success,
    String? errorMessage,
    String? stackTrace,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final entry = SecurityLogEntry(
        id: _generateLogId(),
        level: level,
        category: category,
        event: event,
        userId: userId,
        metadata: metadata,
        success: success,
        errorMessage: errorMessage,
        stackTrace: stackTrace,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      await _logEntry(entry);
      
      // Critical events trigger immediate sync
      if (level == SecurityLogLevel.critical || level == SecurityLogLevel.forensic) {
        await _syncToServer();
      }
    } catch (e, st) {
      AppLogger.error('Failed to log security event', e, st);
    }
  }

  /// Log authentication attempt
  Future<void> logAuthenticationAttempt({
    required String userId,
    required String method,
    required bool success,
    String? errorMessage,
    String? ipAddress,
    String? userAgent,
  }) async {
    await logSecurityEvent(
      level: success ? SecurityLogLevel.info : SecurityLogLevel.warning,
      category: SecurityLogCategory.authentication,
      event: 'authentication_attempt',
      userId: userId,
      success: success,
      errorMessage: errorMessage,
      ipAddress: ipAddress,
      userAgent: userAgent,
      metadata: {
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log data access
  Future<void> logDataAccess({
    required String userId,
    required String action,
    required String resourceType,
    String? resourceId,
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    await logSecurityEvent(
      level: SecurityLogLevel.info,
      category: SecurityLogCategory.data_access,
      event: 'data_access',
      userId: userId,
      success: success,
      metadata: {
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        ...?metadata,
      },
    );
  }

  /// Log configuration change
  Future<void> logConfigurationChange({
    required String userId,
    required String setting,
    required String oldValue,
    required String newValue,
    bool success = true,
  }) async {
    await logSecurityEvent(
      level: SecurityLogLevel.warning,
      category: SecurityLogCategory.configuration_change,
      event: 'configuration_changed',
      userId: userId,
      success: success,
      metadata: {
        'setting': setting,
        'oldValue': oldValue,
        'newValue': newValue,
      },
    );
  }

  /// Log Dead Man's Switch events
  Future<void> logDeadMansSwitchEvent({
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
    bool success = true,
  }) async {
    await logSecurityEvent(
      level: SecurityLogLevel.warning,
      category: SecurityLogCategory.system_event,
      event: 'dead_mans_switch_$action',
      userId: userId,
      success: success,
      metadata: metadata,
    );
  }

  /// Log business events
  Future<void> logBusinessEvent({
    required String userId,
    required String event,
    required Map<String, dynamic> businessData,
    bool success = true,
  }) async {
    await logSecurityEvent(
      level: SecurityLogLevel.info,
      category: SecurityLogCategory.business_event,
      event: event,
      userId: userId,
      success: success,
      metadata: businessData,
    );
  }

  /// Get security logs with filtering
  Future<List<SecurityLogEntry>> getSecurityLogs({
    SecurityLogFilter? filter,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final logs = await _loadLogs();
      var filteredLogs = logs;
      
      if (filter != null) {
        filteredLogs = logs.where(filter.matches).toList();
      }
      
      // Sort by timestamp descending
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply pagination
      final start = offset;
      final end = (start + limit).clamp(0, filteredLogs.length);
      
      return filteredLogs.sublist(start, end);
    } catch (e, st) {
      AppLogger.error('Failed to get security logs', e, st);
      return [];
    }
  }

  /// Get security statistics
  Future<Map<String, dynamic>> getSecurityStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final filter = SecurityLogFilter(
        startDate: startDate,
        endDate: endDate,
      );
      
      final logs = await getSecurityLogs(filter: filter, limit: 10000);
      
      final stats = <String, dynamic>{
        'totalEvents': logs.length,
        'byLevel': <String, int>{},
        'byCategory': <String, int>{},
        'byUser': <String, int>{},
        'successRate': 0.0,
        'criticalEvents': 0,
        'failedAuthentications': 0,
        'dataAccessEvents': 0,
        'configurationChanges': 0,
      };

      int successCount = 0;
      
      for (final log in logs) {
        // Count by level
        final levelName = log.level.name;
        stats['byLevel'][levelName] = (stats['byLevel'][levelName] ?? 0) + 1;
        
        // Count by category
        final categoryName = log.category.name;
        stats['byCategory'][categoryName] = (stats['byCategory'][categoryName] ?? 0) + 1;
        
        // Count by user
        if (log.userId != null) {
          stats['byUser'][log.userId!] = (stats['byUser'][log.userId!] ?? 0) + 1;
        }
        
        // Success rate
        if (log.success == true) successCount++;
        
        // Specific counters
        if (log.level == SecurityLogLevel.critical) stats['criticalEvents']++;
        if (log.category == SecurityLogCategory.authentication && log.success == false) {
          stats['failedAuthentications']++;
        }
        if (log.category == SecurityLogCategory.data_access) stats['dataAccessEvents']++;
        if (log.category == SecurityLogCategory.configuration_change) stats['configurationChanges']++;
      }
      
      stats['successRate'] = logs.isNotEmpty ? (successCount / logs.length) * 100 : 0.0;
      
      return stats;
    } catch (e, st) {
      AppLogger.error('Failed to get security statistics', e, st);
      return {};
    }
  }

  /// Export logs for compliance/forensics
  Future<String> exportLogs({
    SecurityLogFilter? filter,
    String format = 'json',
  }) async {
    try {
      final logs = await getSecurityLogs(filter: filter, limit: 10000);
      
      if (format.toLowerCase() == 'csv') {
        return _exportToCsv(logs);
      } else {
        return jsonEncode({
          'exportedAt': DateTime.now().toIso8601String(),
          'totalLogs': logs.length,
          'logs': logs.map((log) => log.toJson()).toList(),
        });
      }
    } catch (e, st) {
      AppLogger.error('Failed to export logs', e, st);
      return '';
    }
  }

  /// Clear old logs to prevent storage bloat
  Future<void> clearOldLogs({Duration? olderThan}) async {
    try {
      final cutoffDate = olderThan != null 
          ? DateTime.now().subtract(olderThan)
          : DateTime.now().subtract(const Duration(days: 90));
      
      final logs = await _loadLogs();
      final filteredLogs = logs.where((log) => log.timestamp.isAfter(cutoffDate)).toList();
      
      await _saveLogs(filteredLogs);
      
      AppLogger.info('Cleared ${logs.length - filteredLogs.length} old log entries');
    } catch (e, st) {
      AppLogger.error('Failed to clear old logs', e, st);
    }
  }

  /// Private methods
  
  Future<void> _logEntry(SecurityLogEntry entry) async {
    try {
      // Add to local storage
      final logs = await _loadLogs();
      logs.add(entry);
      
      // Maintain size limit
      if (logs.length > _maxLogSize) {
        logs.removeRange(0, logs.length - _maxLogSize);
      }
      
      await _saveLogs(logs);
      
      // Add to buffer for server sync
      await _addToBuffer(entry);
      
      AppLogger.debug('Security log entry added: ${entry.event}');
    } catch (e, st) {
      AppLogger.error('Failed to log entry', e, st);
    }
  }

  Future<List<SecurityLogEntry>> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_logKey) ?? [];
      
      return logsJson
          .map((json) => SecurityLogEntry.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to load logs', e, st);
      return [];
    }
  }

  Future<void> _saveLogs(List<SecurityLogEntry> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = logs.map((log) => jsonEncode(log.toJson())).toList();
      
      await prefs.setStringList(_logKey, logsJson);
    } catch (e, st) {
      AppLogger.error('Failed to save logs', e, st);
    }
  }

  Future<void> _addToBuffer(SecurityLogEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = prefs.getStringList(_bufferKey) ?? [];
      
      bufferJson.add(jsonEncode(entry.toJson()));
      
      // Maintain buffer size
      if (bufferJson.length > _bufferSize) {
        bufferJson.removeRange(0, bufferJson.length - _bufferSize);
      }
      
      await prefs.setStringList(_bufferKey, bufferJson);
    } catch (e, st) {
      AppLogger.error('Failed to add to buffer', e, st);
    }
  }

  Future<void> _syncToServer() async {
    if (_serverEndpoint == null || !_isOnline) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = prefs.getStringList(_bufferKey) ?? [];
      
      if (bufferJson.isEmpty) return;
      
      final logs = bufferJson
          .map((json) => SecurityLogEntry.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      final response = await http.post(
        Uri.parse('$_serverEndpoint/api/logs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({
          'logs': logs.map((log) => log.toJson()).toList(),
          'deviceId': await _getDeviceId(),
          'appVersion': await _getAppVersion(),
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        // Clear buffer on successful sync
        await prefs.setStringList(_bufferKey, []);
        AppLogger.info('Security logs synced to server (${logs.length} entries)');
      } else {
        AppLogger.warning('Failed to sync logs to server: ${response.statusCode}');
      }
    } catch (e, st) {
      AppLogger.error('Failed to sync logs to server', e, st);
    }
  }

  Future<void> _startSyncTimer() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await _syncToServer();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      if (_serverEndpoint != null) {
        final response = await http.get(
          Uri.parse('$_serverEndpoint/api/health'),
        ).timeout(const Duration(seconds: 5));
        
        _isOnline = response.statusCode == 200;
      } else {
        _isOnline = false;
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        _config = jsonDecode(configJson) as Map<String, dynamic>;
      } else {
        _config = {
          'logLevel': 'info',
          'enableRemoteSync': true,
          'retentionDays': 90,
          'maxLogSize': _maxLogSize,
        };
        await prefs.setString(_configKey, jsonEncode(_config!));
      }
    } catch (e, st) {
      AppLogger.error('Failed to load configuration', e, st);
    }
  }

  String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(10000);
    return 'log_${timestamp}_$random';
  }

  Future<String> _getAuthToken() async {
    // In production, this would get the auth token from secure storage
    return 'Bearer_token_placeholder';
  }

  Future<String> _getDeviceId() async {
    // In production, this would get a unique device identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _getAppVersion() async {
    // In production, this would get the actual app version
    return '3.0.0';
  }

  String _exportToCsv(List<SecurityLogEntry> logs) {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('ID,Level,Category,Event,User ID,Timestamp,IP Address,User Agent,Success,Error Message');
    
    // CSV rows
    for (final log in logs) {
      buffer.writeln('"${log.id}",'
          '"${log.level.name}",'
          '"${log.category.name}",'
          '"${log.event}",'
          '"${log.userId ?? ''}",'
          '"${log.timestamp.toIso8601String()}",'
          '"${log.ipAddress ?? ''}",'
          '"${log.userAgent ?? ''}",'
          '"${log.success ?? ''}",'
          '"${log.errorMessage ?? ''}"');
    }
    
    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }
}
