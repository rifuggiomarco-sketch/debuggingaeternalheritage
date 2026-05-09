// v2.5 - Enhanced Error Handling Service
// Provides comprehensive error handling, user feedback, and recovery mechanisms
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';
import 'security_service.dart';

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

enum ErrorCategory {
  network,
  authentication,
  encryption,
  storage,
  validation,
  system,
  user,
}

class AppError {
  final String code;
  final String title;
  final String message;
  final String? technicalDetails;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic>? context;
  final List<String>? suggestedActions;
  
  AppError({
    required this.code,
    required this.title,
    required this.message,
    this.technicalDetails,
    required this.severity,
    required this.category,
    DateTime? timestamp,
    this.userId,
    this.context,
    this.suggestedActions,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'code': code,
    'title': title,
    'message': message,
    'technicalDetails': technicalDetails,
    'severity': severity.name,
    'category': category.name,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'context': context,
    'suggestedActions': suggestedActions,
  };
  
  factory AppError.fromJson(Map<String, dynamic> json) => AppError(
    code: json['code'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    technicalDetails: json['technicalDetails'] as String?,
    severity: ErrorSeverity.values.firstWhere((s) => s.name == json['severity']),
    category: ErrorCategory.values.firstWhere((c) => c.name == json['category']),
    timestamp: DateTime.parse(json['timestamp'] as String),
    userId: json['userId'] as String?,
    context: json['context'] as Map<String, dynamic>?,
    suggestedActions: (json['suggestedActions'] as List<dynamic>).cast<String>(),
  );
}

class ErrorHandlingService {
  ErrorHandlingService._();
  static final ErrorHandlingService _instance = ErrorHandlingService._();
  factory ErrorHandlingService() => _instance;
  
  static const _errorLogKey = 'app_error_log';
  static const _maxErrorLogSize = 100;
  
  final SecurityService _security = SecurityService();
  final StreamController<AppError> _errorStreamController = StreamController<AppError>.broadcast();
  
  Stream<AppError> get errorStream => _errorStreamController.stream;
  
  /// Handle and log an error with user-friendly feedback
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? userId,
    ErrorCategory? category,
    Map<String, dynamic>? context,
    List<String>? suggestedActions,
  }) async {
    try {
      final appError = _createAppError(
        error,
        stackTrace: stackTrace,
        userId: userId,
        category: category,
        context: context,
        suggestedActions: suggestedActions,
      );
      
      // Log error
      await _logError(appError);
      
      // Broadcast error for UI components
      _errorStreamController.add(appError);
      
      // Handle critical errors
      if (appError.severity == ErrorSeverity.critical) {
        await _handleCriticalError(appError);
      }
      
      // Log security event for security-related errors
      if (appError.category == ErrorCategory.authentication || 
          appError.category == ErrorCategory.encryption) {
        await _security.logSecurityEvent(
          'security_error',
          userId: userId,
          metadata: {
            'errorCode': appError.code,
            'category': appError.category.name,
          },
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to handle error', e, st);
    }
  }
  
  /// Create user-friendly error from exception
  AppError _createAppError(
    dynamic error, {
    StackTrace? stackTrace,
    String? userId,
    ErrorCategory? category,
    Map<String, dynamic>? context,
    List<String>? suggestedActions,
  }) {
    final timestamp = DateTime.now();
    
    // Handle common error types
    if (error is SecurityViolationException) {
      return AppError(
        code: 'SECURITY_VIOLATION',
        title: 'Security Violation',
        message: 'A security violation was detected. Please try again.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.error,
        category: ErrorCategory.authentication,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Check your input for invalid characters',
          'Wait a few minutes before trying again',
          'Contact support if the issue persists',
        ],
      );
    }
    
    if (error is SocketException) {
      return AppError(
        code: 'NETWORK_ERROR',
        title: 'Network Connection Error',
        message: 'Unable to connect to the server. Please check your internet connection.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.error,
        category: ErrorCategory.network,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Check your internet connection',
          'Try again in a few moments',
          'Contact your network administrator if the problem persists',
        ],
      );
    }
    
    if (error is TimeoutException) {
      return AppError(
        code: 'TIMEOUT_ERROR',
        title: 'Request Timeout',
        message: 'The operation took too long to complete. Please try again.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.warning,
        category: ErrorCategory.network,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Try again with a better connection',
          'Reduce the amount of data being processed',
          'Contact support if timeouts persist',
        ],
      );
    }
    
    if (error is FormatException) {
      return AppError(
        code: 'FORMAT_ERROR',
        title: 'Data Format Error',
        message: 'The data format is invalid. Please check your input.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.error,
        category: ErrorCategory.validation,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Check the format of your input data',
          'Ensure all required fields are filled',
          'Contact support if you need assistance',
        ],
      );
    }
    
    if (error is FileSystemException) {
      return AppError(
        code: 'FILE_SYSTEM_ERROR',
        title: 'File System Error',
        message: 'Unable to access files. Please check your storage permissions.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.error,
        category: ErrorCategory.storage,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Check storage permissions',
          'Ensure sufficient storage space',
          'Restart the application',
        ],
      );
    }
    
    // Handle argument errors
    if (error is ArgumentError) {
      return AppError(
        code: 'ARGUMENT_ERROR',
        title: 'Invalid Input',
        message: error.message ?? 'Invalid input provided.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.warning,
        category: ErrorCategory.validation,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Check your input values',
          'Ensure all required fields are provided',
          'Review the input format requirements',
        ],
      );
    }
    
    // Handle state errors
    if (error is StateError) {
      return AppError(
        code: 'STATE_ERROR',
        title: 'Application State Error',
        message: 'The application is in an invalid state. Please restart.',
        technicalDetails: error.toString(),
        severity: ErrorSeverity.error,
        category: ErrorCategory.system,
        timestamp: timestamp,
        userId: userId,
        context: context,
        suggestedActions: [
          'Restart the application',
          'Clear application cache',
          'Contact support if the issue persists',
        ],
      );
    }
    
    // Default error handling
    return AppError(
      code: 'UNKNOWN_ERROR',
      title: 'Unexpected Error',
      message: 'An unexpected error occurred. Please try again.',
      technicalDetails: error.toString(),
      severity: ErrorSeverity.error,
      category: category ?? ErrorCategory.system,
      timestamp: timestamp,
      userId: userId,
      context: context,
      suggestedActions: suggestedActions ?? [
        'Try the operation again',
        'Restart the application',
        'Contact support if the issue persists',
      ],
    );
  }
  
  /// Log error to persistent storage
  Future<void> _logError(AppError error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogJson = prefs.getStringList(_errorLogKey) ?? [];
      
      errorLogJson.add(jsonEncode(error.toJson()));
      
      // Keep only the most recent errors
      if (errorLogJson.length > _maxErrorLogSize) {
        errorLogJson.removeRange(0, errorLogJson.length - _maxErrorLogSize);
      }
      
      await prefs.setStringList(_errorLogKey, errorLogJson);
      
      // Log to app logger
      AppLogger.error(
        'Error logged: ${error.code}',
        error,
        StackTrace.current,
      );
    } catch (e, st) {
      AppLogger.error('Failed to log error', e, st);
    }
  }
  
  /// Handle critical errors
  Future<void> _handleCriticalError(AppError error) async {
    try {
      // Log critical error
      AppLogger.critical('Critical error occurred: ${error.code}', error);
      
      // In production, you might want to:
      // 1. Send crash report to crash reporting service
      // 2. Disable certain features
      // 3. Force application restart
      // 4. Notify administrators
      
      await _security.logSecurityEvent(
        'critical_error',
        userId: error.userId,
        metadata: {
          'errorCode': error.code,
          'category': error.category.name,
        },
      );
    } catch (e, st) {
      AppLogger.error('Failed to handle critical error', e, st);
    }
  }
  
  /// Get recent errors for debugging
  Future<List<AppError>> getRecentErrors({int limit = 20}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogJson = prefs.getStringList(_errorLogKey) ?? [];
      
      final errors = errorLogJson
          .map((json) => AppError.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      // Sort by timestamp descending and limit
      errors.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return errors.take(limit).toList();
    } catch (e, st) {
      AppLogger.error('Failed to retrieve recent errors', e, st);
      return [];
    }
  }
  
  /// Clear error log
  Future<void> clearErrorLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorLogKey);
      AppLogger.info('Error log cleared');
    } catch (e, st) {
      AppLogger.error('Failed to clear error log', e, st);
    }
  }
  
  /// Create specific error types
  AppError createNetworkError(String message, {String? technicalDetails}) {
    return AppError(
      code: 'NETWORK_ERROR',
      title: 'Network Error',
      message: message,
      technicalDetails: technicalDetails,
      severity: ErrorSeverity.error,
      category: ErrorCategory.network,
    );
  }
  
  AppError createAuthenticationError(String message, {String? technicalDetails}) {
    return AppError(
      code: 'AUTH_ERROR',
      title: 'Authentication Error',
      message: message,
      technicalDetails: technicalDetails,
      severity: ErrorSeverity.error,
      category: ErrorCategory.authentication,
      suggestedActions: [
        'Check your credentials',
        'Try logging out and back in',
        'Reset your password if needed',
      ],
    );
  }
  
  AppError createEncryptionError(String message, {String? technicalDetails}) {
    return AppError(
      code: 'ENCRYPTION_ERROR',
      title: 'Encryption Error',
      message: message,
      technicalDetails: technicalDetails,
      severity: ErrorSeverity.critical,
      category: ErrorCategory.encryption,
      suggestedActions: [
        'Restart the application',
        'Check your device security settings',
        'Contact support immediately',
      ],
    );
  }
  
  AppError createValidationError(String message, {String? technicalDetails}) {
    return AppError(
      code: 'VALIDATION_ERROR',
      title: 'Validation Error',
      message: message,
      technicalDetails: technicalDetails,
      severity: ErrorSeverity.warning,
      category: ErrorCategory.validation,
      suggestedActions: [
        'Check your input format',
        'Ensure all required fields are filled',
        'Review the input requirements',
      ],
    );
  }
  
  AppError createStorageError(String message, {String? technicalDetails}) {
    return AppError(
      code: 'STORAGE_ERROR',
      title: 'Storage Error',
      message: message,
      technicalDetails: technicalDetails,
      severity: ErrorSeverity.error,
      category: ErrorCategory.storage,
      suggestedActions: [
        'Check storage permissions',
        'Ensure sufficient storage space',
        'Restart the application',
      ],
    );
  }
  
  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }
}

/// Extension for easier error handling in async operations
extension ErrorHandling on Future {
  Future<T?> withErrorHandling<T>({
    String? userId,
    ErrorCategory? category,
    Map<String, dynamic>? context,
    List<String>? suggestedActions,
  }) async {
    try {
      return await this as T;
    } catch (error, stackTrace) {
      await ErrorHandlingService().handleError(
        error,
        stackTrace: stackTrace,
        userId: userId,
        category: category,
        context: context,
        suggestedActions: suggestedActions,
      );
      return null;
    }
  }
}
