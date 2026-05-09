// v2.5 - Enhanced Security Service
// Provides input validation, rate limiting, session management, and audit logging
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';

class SecurityViolationException implements Exception {
  final String message;
  final SecurityViolationType type;
  
  SecurityViolationException(this.message, this.type);
  
  @override
  String toString() => 'SecurityViolationException: $message';
}

enum SecurityViolationType {
  rateLimitExceeded,
  invalidInput,
  sessionExpired,
  suspiciousActivity,
}

class SecurityEvent {
  final String eventType;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic>? metadata;
  
  SecurityEvent({
    required this.eventType,
    required this.timestamp,
    this.userId,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'metadata': metadata,
  };
}

class SecurityService {
  SecurityService._();
  static final SecurityService _instance = SecurityService._();
  factory SecurityService() => _instance;
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  
  static const _rateLimitPrefix = 'rate_limit_';
  static const _sessionKey = 'security_session';
  static const _auditLogKey = 'security_audit_log';
  
  // Rate limiting configuration
  static const int maxLoginAttempts = 5;
  static const Duration loginAttemptWindow = Duration(minutes: 15);
  static const int maxPinAttempts = 5;
  static const Duration pinAttemptWindow = Duration(minutes: 10);
  static const int maxRecoveryAttempts = 3;
  static const Duration recoveryAttemptWindow = Duration(hours: 1);
  
  // Session management
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration maxSessionAge = Duration(days: 7);
  
  /// Validates user input against common attack patterns
  String sanitizeInput(String input, {int maxLength = 1000}) {
    if (input.isEmpty) return input;
    
    // Length check
    if (input.length > maxLength) {
      throw SecurityViolationException(
        'Input exceeds maximum length of $maxLength characters',
        SecurityViolationType.invalidInput,
      );
    }
    
    // Remove potentially dangerous characters
    final sanitized = input
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // Control characters
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '') // Script tags
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // JavaScript protocol
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), ''); // Event handlers
    
    // Check for SQL injection patterns
    final sqlPatterns = [
      RegExp(r"('|(\\')|(;)|(\s+(or|and)\s+)|(union\s+select)", caseSensitive: false),
      RegExp(r"(drop\s+table)|(delete\s+from)|(insert\s+into)|(update\s+\w+\s+set)", caseSensitive: false),
    ];
    
    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(sanitized)) {
        throw SecurityViolationException(
          'Potentially malicious input detected',
          SecurityViolationType.invalidInput,
        );
      }
    }
    
    return sanitized;
  }
  
  /// Validates email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  /// Validates phone number format
  bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }
  
  /// Rate limiting check for login attempts
  Future<bool> checkLoginRateLimit(String identifier) async {
    return await _checkRateLimit(
      'login_$identifier',
      maxLoginAttempts,
      loginAttemptWindow,
    );
  }
  
  /// Rate limiting check for PIN attempts
  Future<bool> checkPinRateLimit() async {
    return await _checkRateLimit(
      'pin',
      maxPinAttempts,
      pinAttemptWindow,
    );
  }
  
  /// Rate limiting check for recovery key attempts
  Future<bool> checkRecoveryRateLimit() async {
    return await _checkRateLimit(
      'recovery',
      maxRecoveryAttempts,
      recoveryAttemptWindow,
    );
  }
  
  Future<bool> _checkRateLimit(
    String action,
    int maxAttempts,
    Duration window,
  ) async {
    final key = '$_rateLimitPrefix$action';
    final prefs = await SharedPreferences.getInstance();
    
    final attemptsJson = prefs.getStringList(key) ?? [];
    final now = DateTime.now();
    
    // Filter old attempts outside the window
    final recentAttempts = attemptsJson
        .map((json) => DateTime.parse(json))
        .where((timestamp) => now.difference(timestamp) <= window)
        .toList();
    
    if (recentAttempts.length >= maxAttempts) {
      await _logSecurityEvent(
        'rate_limit_exceeded',
        metadata: {
          'action': action,
          'attempts': recentAttempts.length,
          'maxAttempts': maxAttempts,
        },
      );
      return false;
    }
    
    // Add current attempt
    recentAttempts.add(now);
    await prefs.setStringList(key, recentAttempts.map((dt) => dt.toIso8601String()).toList());
    
    return true;
  }
  
  /// Reset rate limit for a specific action
  Future<void> resetRateLimit(String action) async {
    final key = '$_rateLimitPrefix$action';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
  
  /// Create or update security session
  Future<void> createSession(String userId) async {
    final now = DateTime.now();
    final session = {
      'userId': userId,
      'createdAt': now.toIso8601String(),
      'lastActivity': now.toIso8601String(),
      'sessionId': _generateSessionId(),
    };
    
    await _storage.write(key: _sessionKey, value: jsonEncode(session));
    await _logSecurityEvent('session_created', userId: userId);
  }
  
  /// Validate current session
  Future<bool> isSessionValid() async {
    try {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson == null) return false;
      
      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      final createdAt = DateTime.parse(session['createdAt'] as String);
      final lastActivity = DateTime.parse(session['lastActivity'] as String);
      final now = DateTime.now();
      
      // Check session age
      if (now.difference(createdAt) > maxSessionAge) {
        await invalidateSession();
        return false;
      }
      
      // Check session timeout
      if (now.difference(lastActivity) > sessionTimeout) {
        await invalidateSession();
        return false;
      }
      
      // Update last activity
      session['lastActivity'] = now.toIso8601String();
      await _storage.write(key: _sessionKey, value: jsonEncode(session));
      
      return true;
    } catch (e) {
      AppLogger.error('Session validation error', e);
      return false;
    }
  }
  
  /// Update session activity
  Future<void> updateSessionActivity() async {
    try {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson == null) return;
      
      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      session['lastActivity'] = DateTime.now().toIso8601String();
      await _storage.write(key: _sessionKey, value: jsonEncode(session));
    } catch (e) {
      AppLogger.error('Session activity update error', e);
    }
  }
  
  /// Invalidate current session
  Future<void> invalidateSession() async {
    try {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson != null) {
        final session = jsonDecode(sessionJson) as Map<String, dynamic>;
        await _logSecurityEvent(
          'session_invalidated',
          userId: session['userId'] as String?,
        );
      }
      await _storage.delete(key: _sessionKey);
    } catch (e) {
      AppLogger.error('Session invalidation error', e);
    }
  }
  
  /// Log security events for audit trail (private method)
  Future<void> _logSecurityEvent(
    String eventType, {
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = SecurityEvent(
        eventType: eventType,
        timestamp: DateTime.now(),
        userId: userId,
        metadata: metadata,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final logJson = prefs.getStringList(_auditLogKey) ?? [];
      
      logJson.add(jsonEncode(event.toJson()));
      
      // Keep only last 1000 events
      if (logJson.length > 1000) {
        logJson.removeRange(0, logJson.length - 1000);
      }
      
      await prefs.setStringList(_auditLogKey, logJson);
      
      AppLogger.info('Security event logged: $eventType');
    } catch (e) {
      AppLogger.error('Failed to log security event', e);
    }
  }
  
  /// Public method to log security events with optional timestamp
  Future<void> logSecurityEvent(
    String eventType, {
    String? userId,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) async {
    try {
      final event = SecurityEvent(
        eventType: eventType,
        timestamp: timestamp ?? DateTime.now(),
        userId: userId,
        metadata: metadata,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final logJson = prefs.getStringList(_auditLogKey) ?? [];
      
      logJson.add(jsonEncode(event.toJson()));
      
      // Keep only last 1000 events
      if (logJson.length > 1000) {
        logJson.removeRange(0, logJson.length - 1000);
      }
      
      await prefs.setStringList(_auditLogKey, logJson);
      
      AppLogger.info('Security event logged: $eventType');
    } catch (e) {
      AppLogger.error('Failed to log security event', e);
    }
  }
  
  /// Get recent security events
  Future<List<SecurityEvent>> getSecurityEvents({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logJson = prefs.getStringList(_auditLogKey) ?? [];
      
      final events = logJson
          .map((json) => SecurityEventExtension.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      // Sort by timestamp descending and limit
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return events.take(limit).toList();
    } catch (e) {
      AppLogger.error('Failed to retrieve security events', e);
      return [];
    }
  }
  
  String _generateSessionId() {
    final bytes = sha256.convert(DateTime.now().millisecondsSinceEpoch.toString().codeUnits);
    return bytes.toString();
  }
  
  /// Clear all security data (for testing/reset)
  Future<void> clearAllSecurityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_rateLimitPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      await prefs.remove(_auditLogKey);
      await _storage.delete(key: _sessionKey);
      
      AppLogger.info('All security data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear security data', e);
    }
  }
}

// Extension for SecurityEvent deserialization
extension SecurityEventExtension on SecurityEvent {
  static SecurityEvent fromJson(Map<String, dynamic> json) => SecurityEvent(
    eventType: json['eventType'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    userId: json['userId'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}
