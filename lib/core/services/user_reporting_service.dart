// v3.0 - User Reporting Service
// Provides periodic vault status reports and user analytics
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';
import 'security_service.dart';
import 'advanced_security_logging_service.dart';
import 'enhanced_subscription_service.dart';

enum ReportFrequency {
  weekly,
  monthly,
  quarterly,
  semi_annually,
  annually,
}

enum ReportType {
  vault_status,
  security_summary,
  heir_status,
  subscription_status,
  comprehensive,
}

enum ReportDeliveryMethod {
  email,
  in_app,
  both,
}

class ReportConfig {
  final ReportFrequency frequency;
  final List<ReportType> reportTypes;
  final ReportDeliveryMethod deliveryMethod;
  final String email;
  final bool includeCharts;
  final bool includeDetailedLogs;
  final DateTime? lastSent;
  final bool isActive;
  
  const ReportConfig({
    this.frequency = ReportFrequency.monthly,
    this.reportTypes = const [ReportType.vault_status, ReportType.heir_status],
    this.deliveryMethod = ReportDeliveryMethod.email,
    this.email = '',
    this.includeCharts = false,
    this.includeDetailedLogs = false,
    this.lastSent,
    this.isActive = true,
  });
  
  ReportConfig copyWith({
    ReportFrequency? frequency,
    List<ReportType>? reportTypes,
    ReportDeliveryMethod? deliveryMethod,
    String? email,
    bool? includeCharts,
    bool? includeDetailedLogs,
    DateTime? lastSent,
    bool? isActive,
  }) => ReportConfig(
    frequency: frequency ?? this.frequency,
    reportTypes: reportTypes ?? this.reportTypes,
    deliveryMethod: deliveryMethod ?? this.deliveryMethod,
    email: email ?? this.email,
    includeCharts: includeCharts ?? this.includeCharts,
    includeDetailedLogs: includeDetailedLogs ?? this.includeDetailedLogs,
    lastSent: lastSent ?? this.lastSent,
    isActive: isActive ?? this.isActive,
  );
  
  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'reportTypes': reportTypes.map((t) => t.name).toList(),
    'deliveryMethod': deliveryMethod.name,
    'email': email,
    'includeCharts': includeCharts,
    'includeDetailedLogs': includeDetailedLogs,
    'lastSent': lastSent?.toIso8601String(),
    'isActive': isActive,
  };
  
  factory ReportConfig.fromJson(Map<String, dynamic> json) => ReportConfig(
    frequency: ReportFrequency.values.firstWhere((f) => f.name == json['frequency']),
    reportTypes: (json['reportTypes'] as List<dynamic>?)
        ?.map((t) => ReportType.values.firstWhere((r) => r.name == t))
        .toList() ?? [ReportType.vault_status, ReportType.heir_status],
    deliveryMethod: ReportDeliveryMethod.values.firstWhere((d) => d.name == json['deliveryMethod']),
    email: json['email'] as String? ?? '',
    includeCharts: json['includeCharts'] as bool? ?? false,
    includeDetailedLogs: json['includeDetailedLogs'] as bool? ?? false,
    lastSent: json['lastSent'] != null ? DateTime.parse(json['lastSent'] as String) : null,
    isActive: json['isActive'] as bool? ?? true,
  );
}

class VaultStatusReport {
  final String id;
  final DateTime generatedAt;
  final ReportType type;
  final Map<String, dynamic> data;
  final String? htmlContent;
  final String? pdfContent;
  final List<String> attachments;
  
  const VaultStatusReport({
    required this.id,
    required this.generatedAt,
    required this.type,
    required this.data,
    this.htmlContent,
    this.pdfContent,
    this.attachments = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'generatedAt': generatedAt.toIso8601String(),
    'type': type.name,
    'data': data,
    'htmlContent': htmlContent,
    'pdfContent': pdfContent,
    'attachments': attachments,
  };
  
  factory VaultStatusReport.fromJson(Map<String, dynamic> json) => VaultStatusReport(
    id: json['id'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    type: ReportType.values.firstWhere((t) => t.name == json['type']),
    data: json['data'] as Map<String, dynamic>,
    htmlContent: json['htmlContent'] as String?,
    pdfContent: json['pdfContent'] as String?,
    attachments: (json['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}

class UserReportingService {
  UserReportingService._();
  static final UserReportingService _instance = UserReportingService._();
  factory UserReportingService() => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _configKey = 'user_reporting_config_v3';
  static const _reportsKey = 'user_reports_v3';
  static const _maxReports = 100;

  Timer? _reportTimer;
  String? _emailServiceEndpoint;
  
  final SecurityService _security = SecurityService();
  final AdvancedSecurityLoggingService _logging = AdvancedSecurityLoggingService();
  final EnhancedSubscriptionService _subscription = EnhancedSubscriptionService();

  /// Initialize the user reporting service
  Future<void> initialize({String? emailServiceEndpoint}) async {
    try {
      _emailServiceEndpoint = emailServiceEndpoint;
      await _loadReportConfig();
      await _startReportScheduler();
      
      AppLogger.info('User Reporting Service initialized');
    } catch (e, st) {
      AppLogger.error('Failed to initialize user reporting service', e, st);
    }
  }

  /// Configure user reports
  Future<void> configureReports(ReportConfig config) async {
    try {
      // Validate configuration
      if (config.deliveryMethod == ReportDeliveryMethod.email && config.email.isEmpty) {
        throw ArgumentError('Email address is required for email delivery');
      }
      
      if (!_security.isValidEmail(config.email)) {
        throw ArgumentError('Invalid email format');
      }
      
      await _saveReportConfig(config);
      
      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'report_configured',
        businessData: {
          'frequency': config.frequency.name,
          'reportTypes': config.reportTypes.map((t) => t.name).toList(),
          'deliveryMethod': config.deliveryMethod.name,
        },
      );
      
      AppLogger.info('User reports configured');
    } catch (e, st) {
      AppLogger.error('Failed to configure reports', e, st);
      rethrow;
    }
  }

  /// Generate immediate report
  Future<VaultStatusReport> generateReport({
    required ReportType type,
    bool includeCharts = false,
    bool includeDetailedLogs = false,
  }) async {
    try {
      final reportData = await _generateReportData(type, includeCharts, includeDetailedLogs);
      
      final report = VaultStatusReport(
        id: _generateReportId(),
        generatedAt: DateTime.now(),
        type: type,
        data: reportData,
        htmlContent: await _generateHtmlReport(type, reportData),
      );
      
      // Save report
      await _saveReport(report);
      
      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'report_generated',
        businessData: {
          'reportId': report.id,
          'type': type.name,
          'includeCharts': includeCharts,
          'includeDetailedLogs': includeDetailedLogs,
        },
      );
      
      return report;
    } catch (e, st) {
      AppLogger.error('Failed to generate report', e, st);
      rethrow;
    }
  }

  /// Send report to user
  Future<bool> sendReport({
    required VaultStatusReport report,
    ReportDeliveryMethod? method,
    String? email,
  }) async {
    try {
      final config = await _loadReportConfig();
      final deliveryMethod = method ?? config.deliveryMethod;
      final targetEmail = email ?? config.email;
      
      bool success = false;
      
      switch (deliveryMethod) {
        case ReportDeliveryMethod.email:
          success = await _sendEmailReport(report, targetEmail);
          break;
        case ReportDeliveryMethod.in_app:
          success = await _saveInAppReport(report);
          break;
        case ReportDeliveryMethod.both:
          success = await _sendEmailReport(report, targetEmail) && 
                   await _saveInAppReport(report);
          break;
      }
      
      if (success) {
        // Update last sent timestamp
        final updatedConfig = config.copyWith(lastSent: DateTime.now());
        await _saveReportConfig(updatedConfig);
        
        await _logging.logBusinessEvent(
          userId: 'current_user',
          event: 'report_sent',
          businessData: {
            'reportId': report.id,
            'deliveryMethod': deliveryMethod.name,
            'email': targetEmail,
          },
        );
      }
      
      return success;
    } catch (e, st) {
      AppLogger.error('Failed to send report', e, st);
      return false;
    }
  }

  /// Get report history
  Future<List<VaultStatusReport>> getReportHistory({
    ReportType? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final reports = await _loadReports();
      
      var filteredReports = reports;
      
      if (type != null) {
        filteredReports = reports.where((r) => r.type == type).toList();
      }
      
      if (startDate != null) {
        filteredReports = filteredReports.where((r) => r.generatedAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        filteredReports = filteredReports.where((r) => r.generatedAt.isBefore(endDate)).toList();
      }
      
      // Sort by date descending and limit
      filteredReports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      
      return filteredReports.take(limit).toList();
    } catch (e, st) {
      AppLogger.error('Failed to get report history', e, st);
      return [];
    }
  }

  /// Get current report configuration
  Future<ReportConfig> getReportConfig() async {
    return await _loadReportConfig();
  }

  /// Delete report
  Future<bool> deleteReport(String reportId) async {
    try {
      final reports = await _loadReports();
      final filteredReports = reports.where((r) => r.id != reportId).toList();
      
      await _saveReports(filteredReports);
      
      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'report_deleted',
        businessData: {'reportId': reportId},
      );
      
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to delete report', e, st);
      return false;
    }
  }

  /// Private methods

  Future<Map<String, dynamic>> _generateReportData(
    ReportType type,
    bool includeCharts,
    bool includeDetailedLogs,
  ) async {
    switch (type) {
      case ReportType.vault_status:
        return await _generateVaultStatusReport(includeCharts);
      case ReportType.security_summary:
        return await _generateSecuritySummaryReport(includeDetailedLogs);
      case ReportType.heir_status:
        return await _generateHeirStatusReport();
      case ReportType.subscription_status:
        return await _generateSubscriptionStatusReport();
      case ReportType.comprehensive:
        return await _generateComprehensiveReport(includeCharts, includeDetailedLogs);
    }
  }

  Future<Map<String, dynamic>> _generateVaultStatusReport(bool includeCharts) async {
    // This would integrate with the vault service to get actual data
    return {
      'reportType': 'vault_status',
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalDocuments': 25,
        'totalSize': 1024 * 1024 * 50, // 50MB
        'sharedDocuments': 8,
        'categories': {
          'identity': 5,
          'financial': 8,
          'legal': 4,
          'personal': 6,
          'medical': 2,
        },
        'lastUpdated': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      },
      'health': {
        'status': 'healthy',
        'lastBackup': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'encryptionStatus': 'active',
        'storageUtilization': '25%',
      },
      'recentActivity': [
        {
          'action': 'document_added',
          'document': 'passport.pdf',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'action': 'heir_updated',
          'heir': 'John Doe',
          'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
      ],
      'charts': includeCharts ? {
        'documentGrowth': [
          {'date': '2024-01-01', 'count': 10},
          {'date': '2024-02-01', 'count': 15},
          {'date': '2024-03-01', 'count': 20},
          {'date': '2024-04-01', 'count': 25},
        ],
        'categoryDistribution': [
          {'category': 'identity', 'count': 5},
          {'category': 'financial', 'count': 8},
          {'category': 'legal', 'count': 4},
          {'category': 'personal', 'count': 6},
          {'category': 'medical', 'count': 2},
        ],
      } : null,
    };
  }

  Future<Map<String, dynamic>> _generateSecuritySummaryReport(bool includeDetailedLogs) async {
    final securityStats = await _logging.getSecurityStatistics();
    
    return {
      'reportType': 'security_summary',
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalEvents': securityStats['totalEvents'] ?? 0,
        'criticalEvents': securityStats['criticalEvents'] ?? 0,
        'failedAuthentications': securityStats['failedAuthentications'] ?? 0,
        'successRate': securityStats['successRate'] ?? 0.0,
        'dataAccessEvents': securityStats['dataAccessEvents'] ?? 0,
        'configurationChanges': securityStats['configurationChanges'] ?? 0,
      },
      'securityHealth': {
        'status': 'good',
        'lastSecurityScan': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'vulnerabilitiesFound': 0,
        'recommendations': [
          'Enable multi-factor authentication',
          'Review heir permissions',
          'Update recovery key',
        ],
      },
      'recentSecurityEvents': includeDetailedLogs ? [
        {
          'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          'event': 'login_success',
          'level': 'info',
          'user': 'current_user',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'event': 'configuration_changed',
          'level': 'warning',
          'user': 'current_user',
        },
      ] : null,
      'byLevel': securityStats['byLevel'] ?? {},
      'byCategory': securityStats['byCategory'] ?? {},
    };
  }

  Future<Map<String, dynamic>> _generateHeirStatusReport() async {
    return {
      'reportType': 'heir_status',
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': {
        'totalHeirs': 3,
        'confirmedHeirs': 3,
        'pendingConfirmations': 0,
        'lastNotified': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      'heirs': [
        {
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'relationship': 'Spouse',
          'confirmed': true,
          'confirmedAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          'accessLevel': 'full',
          'lastNotified': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
        {
          'name': 'Jane Doe',
          'email': 'jane.doe@example.com',
          'relationship': 'Child',
          'confirmed': true,
          'confirmedAt': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
          'accessLevel': 'conditional',
          'allowedFolders': ['financial', 'legal'],
          'lastNotified': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
        {
          'name': 'Bob Smith',
          'email': 'bob.smith@example.com',
          'relationship': 'Sibling',
          'confirmed': true,
          'confirmedAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'accessLevel': 'conditional',
          'allowedFolders': ['identity'],
          'lastNotified': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      ],
      'notifications': {
        'lastNotificationSent': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'notificationMethod': 'email',
        'deliveryStatus': 'delivered',
      },
    };
  }

  Future<Map<String, dynamic>> _generateSubscriptionStatusReport() async {
    final subscription = await _subscription.getCurrentSubscription();
    final analytics = await _subscription.getSubscriptionAnalytics();
    
    return {
      'reportType': 'subscription_status',
      'generatedAt': DateTime.now().toIso8601String(),
      'currentSubscription': subscription?.toJson(),
      'analytics': analytics,
      'billing': {
        'nextBillingDate': subscription?.currentPeriodEnd?.toIso8601String(),
        'amount': subscription?.tier.price,
        'currency': 'USD',
        'autoRenew': subscription?.autoRenew ?? true,
        'paymentMethod': 'card',
      },
      'usage': {
        'documentsUsed': 25,
        'documentsLimit': subscription?.tier.maxDocuments ?? 10,
        'heirsUsed': 3,
        'heirsLimit': subscription?.tier.maxHeirs ?? 1,
        'features': {
          'deadMansSwitch': subscription?.tier != SubscriptionTierV3.free,
          'conditionalInheritance': subscription?.tier != SubscriptionTierV3.free,
          'multiChannelCheckIn': subscription?.tier != SubscriptionTierV3.free,
        },
      },
    };
  }

  Future<Map<String, dynamic>> _generateComprehensiveReport(
    bool includeCharts,
    bool includeDetailedLogs,
  ) async {
    final vaultStatus = await _generateVaultStatusReport(includeCharts);
    final securitySummary = await _generateSecuritySummaryReport(includeDetailedLogs);
    final heirStatus = await _generateHeirStatusReport();
    final subscriptionStatus = await _generateSubscriptionStatusReport();
    
    return {
      'reportType': 'comprehensive',
      'generatedAt': DateTime.now().toIso8601String(),
      'vaultStatus': vaultStatus,
      'securitySummary': securitySummary,
      'heirStatus': heirStatus,
      'subscriptionStatus': subscriptionStatus,
      'overallHealth': {
        'status': 'excellent',
        'score': 95,
        'recommendations': [
          'Consider upgrading to Premium for unlimited documents',
          'Enable SMS notifications for Dead Man\'s Switch',
          'Review and update heir permissions',
        ],
      },
    };
  }

  Future<String> _generateHtmlReport(ReportType type, Map<String, dynamic> data) async {
    // Generate HTML content for the report
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<title>Digital Vault Heritage - ${type.name.toUpperCase()} Report</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Arial, sans-serif; margin: 20px; color: #333; }');
    buffer.writeln('.header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; }');
    buffer.writeln('.section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 8px; }');
    buffer.writeln('.summary { background: #ecf0f1; padding: 15px; border-radius: 8px; }');
    buffer.writeln('.metric { display: inline-block; margin: 10px; padding: 10px; background: #3498db; color: white; border-radius: 4px; }');
    buffer.writeln('.status-good { color: #27ae60; }');
    buffer.writeln('.status-warning { color: #f39c12; }');
    buffer.writeln('.status-critical { color: #e74c3c; }');
    buffer.writeln('table { width: 100%; border-collapse: collapse; margin: 10px 0; }');
    buffer.writeln('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    buffer.writeln('th { background-color: #f2f2f2; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    
    // Header
    buffer.writeln('<div class="header">');
    buffer.writeln('<h1>Digital Vault Heritage</h1>');
    buffer.writeln('<h2>${type.name.toUpperCase()} Report</h2>');
    buffer.writeln('<p>Generated on: ${DateTime.now().toIso8601String()}</p>');
    buffer.writeln('</div>');
    
    // Report content based on type
    switch (type) {
      case ReportType.vault_status:
        _generateVaultStatusHtml(buffer, data);
        break;
      case ReportType.security_summary:
        _generateSecuritySummaryHtml(buffer, data);
        break;
      case ReportType.heir_status:
        _generateHeirStatusHtml(buffer, data);
        break;
      case ReportType.subscription_status:
        _generateSubscriptionStatusHtml(buffer, data);
        break;
      case ReportType.comprehensive:
        _generateComprehensiveHtml(buffer, data);
        break;
    }
    
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    return buffer.toString();
  }

  void _generateVaultStatusHtml(StringBuffer buffer, Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>;
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Vault Overview</h2>');
    buffer.writeln('<div class="summary">');
    buffer.writeln('<div class="metric">Documents: ${summary['totalDocuments']}</div>');
    buffer.writeln('<div class="metric">Size: ${(summary['totalSize'] / (1024 * 1024)).toStringAsFixed(1)} MB</div>');
    buffer.writeln('<div class="metric">Shared: ${summary['sharedDocuments']}</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Categories</h2>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>Category</th><th>Count</th></tr>');
    
    final categories = summary['categories'] as Map<String, dynamic>;
    for (final entry in categories.entries) {
      buffer.writeln('<tr><td>${entry.key}</td><td>${entry.value}</td></tr>');
    }
    
    buffer.writeln('</table>');
    buffer.writeln('</div>');
  }

  void _generateSecuritySummaryHtml(StringBuffer buffer, Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>;
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Security Overview</h2>');
    buffer.writeln('<div class="summary">');
    buffer.writeln('<div class="metric">Total Events: ${summary['totalEvents']}</div>');
    buffer.writeln('<div class="metric">Success Rate: ${summary['successRate'].toStringAsFixed(1)}%</div>');
    buffer.writeln('<div class="metric ${summary['criticalEvents'] > 0 ? "status-critical" : "status-good"}">Critical Events: ${summary['criticalEvents']}</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    
    final health = data['securityHealth'] as Map<String, dynamic>;
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Security Health</h2>');
    buffer.writeln('<p>Status: <span class="status-${health['status']}">${health['status']}</span></p>');
    buffer.writeln('<p>Last Security Scan: ${health['lastSecurityScan']}</p>');
    buffer.writeln('</div>');
  }

  void _generateHeirStatusHtml(StringBuffer buffer, Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>;
    final heirs = data['heirs'] as List<dynamic>;
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Heir Overview</h2>');
    buffer.writeln('<div class="summary">');
    buffer.writeln('<div class="metric">Total Heirs: ${summary['totalHeirs']}</div>');
    buffer.writeln('<div class="metric">Confirmed: ${summary['confirmedHeirs']}</div>');
    buffer.writeln('<div class="metric">Pending: ${summary['pendingConfirmations']}</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Heir Details</h2>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>Name</th><th>Email</th><th>Relationship</th><th>Status</th><th>Access Level</th></tr>');
    
    for (final heir in heirs) {
      final heirData = heir as Map<String, dynamic>;
      buffer.writeln('<tr>');
      buffer.writeln('<td>${heirData['name']}</td>');
      buffer.writeln('<td>${heirData['email']}</td>');
      buffer.writeln('<td>${heirData['relationship']}</td>');
      buffer.writeln('<td><span class="status-${heirData['confirmed'] ? "good" : "warning"}">${heirData['confirmed'] ? "Confirmed" : "Pending"}</span></td>');
      buffer.writeln('<td>${heirData['accessLevel']}</td>');
      buffer.writeln('</tr>');
    }
    
    buffer.writeln('</table>');
    buffer.writeln('</div>');
  }

  void _generateSubscriptionStatusHtml(StringBuffer buffer, Map<String, dynamic> data) {
    final subscription = data['currentSubscription'];
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Subscription Details</h2>');
    
    if (subscription != null) {
      buffer.writeln('<p><strong>Tier:</strong> ${subscription['tier']}</p>');
      buffer.writeln('<p><strong>Status:</strong> <span class="status-${subscription['status'] == 'succeeded' ? 'good' : 'warning'}">${subscription['status']}</span></p>');
      buffer.writeln('<p><strong>Billing Cycle:</strong> ${subscription['billingCycle']}</p>');
      buffer.writeln('<p><strong>Auto Renew:</strong> ${subscription['autoRenew'] ? 'Yes' : 'No'}</p>');
    } else {
      buffer.writeln('<p>No active subscription</p>');
    }
    
    buffer.writeln('</div>');
    
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Usage</h2>');
    
    final usage = data['usage'] as Map<String, dynamic>;
    buffer.writeln('<p><strong>Documents:</strong> ${usage['documentsUsed']} / ${usage['documentsLimit']}</p>');
    buffer.writeln('<p><strong>Heirs:</strong> ${usage['heirsUsed']} / ${usage['heirsLimit']}</p>');
    buffer.writeln('</div>');
  }

  void _generateComprehensiveHtml(StringBuffer buffer, Map<String, dynamic> data) {
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Overall Health</h2>');
    
    final health = data['overallHealth'] as Map<String, dynamic>;
    buffer.writeln('<div class="summary">');
    buffer.writeln('<div class="metric">Health Score: ${health['score']}</div>');
    buffer.writeln('<div class="metric status-${health['status']}">Status: ${health['status']}</div>');
    buffer.writeln('</div>');
    
    buffer.writeln('<h3>Recommendations</h3>');
    buffer.writeln('<ul>');
    for (final recommendation in health['recommendations'] as List<dynamic>) {
      buffer.writeln('<li>$recommendation</li>');
    }
    buffer.writeln('</ul>');
    buffer.writeln('</div>');
    
    // Include sections from other report types
    _generateVaultStatusHtml(buffer, data['vaultStatus']);
    _generateSecuritySummaryHtml(buffer, data['securitySummary']);
    _generateHeirStatusHtml(buffer, data['heirStatus']);
    _generateSubscriptionStatusHtml(buffer, data['subscriptionStatus']);
  }

  Future<bool> _sendEmailReport(VaultStatusReport report, String email) async {
    if (_emailServiceEndpoint == null) {
      AppLogger.warning('Email service endpoint not configured');
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_emailServiceEndpoint/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': email,
          'subject': 'Digital Vault Heritage - ${report.type.name.toUpperCase()} Report',
          'html': report.htmlContent,
          'attachments': report.attachments,
        }),
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e, st) {
      AppLogger.error('Failed to send email report', e, st);
      return false;
    }
  }

  Future<bool> _saveInAppReport(VaultStatusReport report) async {
    try {
      final reports = await _loadReports();
      reports.add(report);
      
      // Maintain size limit
      if (reports.length > _maxReports) {
        reports.removeRange(0, reports.length - _maxReports);
      }
      
      await _saveReports(reports);
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to save in-app report', e, st);
      return false;
    }
  }

  Future<void> _startReportScheduler() async {
    _reportTimer?.cancel();
    
    final config = await _loadReportConfig();
    if (!config.isActive) return;
    
    final interval = _getReportInterval(config.frequency);
    
    _reportTimer = Timer.periodic(interval, (_) async {
      try {
        await _checkAndSendScheduledReports();
      } catch (e, st) {
        AppLogger.error('Scheduled report check failed', e, st);
      }
    });
  }

  Duration _getReportInterval(ReportFrequency frequency) {
    switch (frequency) {
      case ReportFrequency.weekly:
        return const Duration(days: 7);
      case ReportFrequency.monthly:
        return const Duration(days: 30);
      case ReportFrequency.quarterly:
        return const Duration(days: 90);
      case ReportFrequency.semi_annually:
        return const Duration(days: 180);
      case ReportFrequency.annually:
        return const Duration(days: 365);
    }
  }

  Future<void> _checkAndSendScheduledReports() async {
    final config = await _loadReportConfig();
    
    if (!config.isActive) return;
    
    // Check if it's time to send reports
    if (config.lastSent != null) {
      final nextSend = config.lastSent!.add(_getReportInterval(config.frequency));
      if (DateTime.now().isBefore(nextSend)) {
        return; // Not time yet
      }
    }
    
    // Generate and send reports
    for (final reportType in config.reportTypes) {
      try {
        final report = await generateReport(
          type: reportType,
          includeCharts: config.includeCharts,
          includeDetailedLogs: config.includeDetailedLogs,
        );
        
        await sendReport(report: report);
      } catch (e, st) {
        AppLogger.error('Failed to generate/send scheduled report', e, st);
      }
    }
  }

  Future<ReportConfig> _loadReportConfig() async {
    try {
      final configJson = await _storage.read(key: _configKey);
      if (configJson != null) {
        return ReportConfig.fromJson(jsonDecode(configJson) as Map<String, dynamic>);
      }
    } catch (e, st) {
      AppLogger.error('Failed to load report config', e, st);
    }
    return const ReportConfig();
  }

  Future<void> _saveReportConfig(ReportConfig config) async {
    try {
      await _storage.write(key: _configKey, value: jsonEncode(config.toJson()));
    } catch (e, st) {
      AppLogger.error('Failed to save report config', e, st);
    }
  }

  Future<List<VaultStatusReport>> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_reportsKey) ?? [];
      
      return reportsJson
          .map((json) => VaultStatusReport.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to load reports', e, st);
      return [];
    }
  }

  Future<void> _saveReports(List<VaultStatusReport> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((report) => jsonEncode(report.toJson())).toList();
      
      await prefs.setStringList(_reportsKey, reportsJson);
    } catch (e, st) {
      AppLogger.error('Failed to save reports', e, st);
    }
  }

  Future<void> _saveReport(VaultStatusReport report) async {
    try {
      final reports = await _loadReports();
      reports.add(report);
      
      // Maintain size limit
      if (reports.length > _maxReports) {
        reports.removeRange(0, reports.length - _maxReports);
      }
      
      await _saveReports(reports);
    } catch (e, st) {
      AppLogger.error('Failed to save report', e, st);
    }
  }

  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(10000)}';
  }

  /// Dispose resources
  void dispose() {
    _reportTimer?.cancel();
  }
}
