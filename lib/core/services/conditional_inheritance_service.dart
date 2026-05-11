// v3.0 - Conditional Inheritance Service
// Provides sophisticated inheritance rules and access control for heirs
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';
import 'security_service.dart';
import 'advanced_security_logging_service.dart';

enum AccessLevel {
  none,
  read_only,
  read_write,
  full_access,
}

enum ConditionType {
  time_based,
  event_based,
  location_based,
  approval_based,
  custom,
}

enum InheritanceStatus {
  pending,
  approved,
  rejected,
  expired,
  conditional,
}

class InheritanceRule {
  final String id;
  final String name;
  final String description;
  final ConditionType conditionType;
  final Map<String, dynamic> conditionData;
  final List<String> allowedHeirs;
  final List<String> allowedFolders;
  final List<String> allowedDocumentTypes;
  final AccessLevel accessLevel;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final DateTime? lastModified;

  const InheritanceRule({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionType,
    required this.conditionData,
    required this.allowedHeirs,
    required this.allowedFolders,
    required this.allowedDocumentTypes,
    required this.accessLevel,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.priority = 0,
    required this.createdAt,
    this.lastModified,
  });

  InheritanceRule copyWith({
    String? name,
    String? description,
    ConditionType? conditionType,
    Map<String, dynamic>? conditionData,
    List<String>? allowedHeirs,
    List<String>? allowedFolders,
    List<String>? allowedDocumentTypes,
    AccessLevel? accessLevel,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? priority,
    DateTime? lastModified,
  }) => InheritanceRule(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    conditionType: conditionType ?? this.conditionType,
    conditionData: conditionData ?? this.conditionData,
    allowedHeirs: allowedHeirs ?? this.allowedHeirs,
    allowedFolders: allowedFolders ?? this.allowedFolders,
    allowedDocumentTypes: allowedDocumentTypes ?? this.allowedDocumentTypes,
    accessLevel: accessLevel ?? this.accessLevel,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    isActive: isActive ?? this.isActive,
    priority: priority ?? this.priority,
    createdAt: createdAt,
    lastModified: lastModified ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'conditionType': conditionType.name,
    'conditionData': conditionData,
    'allowedHeirs': allowedHeirs,
    'allowedFolders': allowedFolders,
    'allowedDocumentTypes': allowedDocumentTypes,
    'accessLevel': accessLevel.name,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isActive': isActive,
    'priority': priority,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified?.toIso8601String(),
  };

  factory InheritanceRule.fromJson(Map<String, dynamic> json) => InheritanceRule(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    conditionType: ConditionType.values.firstWhere((c) => c.name == json['conditionType']),
    conditionData: json['conditionData'] as Map<String, dynamic>,
    allowedHeirs: (json['allowedHeirs'] as List<dynamic>).cast<String>(),
    allowedFolders: (json['allowedFolders'] as List<dynamic>).cast<String>(),
    allowedDocumentTypes: (json['allowedDocumentTypes'] as List<dynamic>).cast<String>(),
    accessLevel: AccessLevel.values.firstWhere((a) => a.name == json['accessLevel']),
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    isActive: json['isActive'] as bool? ?? true,
    priority: json['priority'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified'] as String) : null,
  );
}

class InheritanceRequest {
  final String id;
  final String heirId;
  final List<String> ruleIds;
  final Map<String, dynamic> requestData;
  final InheritanceStatus status;
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final Map<String, dynamic>? reviewData;

  const InheritanceRequest({
    required this.id,
    required this.heirId,
    required this.ruleIds,
    required this.requestData,
    required this.status,
    this.rejectionReason,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'heirId': heirId,
    'ruleIds': ruleIds,
    'requestData': requestData,
    'status': status.name,
    'rejectionReason': rejectionReason,
    'requestedAt': requestedAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
    'reviewData': reviewData,
  };

  factory InheritanceRequest.fromJson(Map<String, dynamic> json) => InheritanceRequest(
    id: json['id'] as String,
    heirId: json['heirId'] as String,
    ruleIds: (json['ruleIds'] as List<dynamic>).cast<String>(),
    requestData: json['requestData'] as Map<String, dynamic>,
    status: InheritanceStatus.values.firstWhere((s) => s.name == json['status']),
    rejectionReason: json['rejectionReason'] as String?,
    requestedAt: DateTime.parse(json['requestedAt'] as String),
    reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
    reviewedBy: json['reviewedBy'] as String?,
    reviewData: json['reviewData'] as Map<String, dynamic>?,
  );
}

class AccessResult {
  final bool granted;
  final AccessLevel accessLevel;
  final List<String> allowedFolders;
  final List<String> allowedDocumentTypes;
  final List<InheritanceRule> appliedRules;
  final String? reason;
  final Map<String, dynamic>? metadata;

  const AccessResult({
    required this.granted,
    required this.accessLevel,
    this.allowedFolders = const [],
    this.allowedDocumentTypes = const [],
    this.appliedRules = const [],
    this.reason,
    this.metadata,
  });
}

class ConditionalInheritanceService {
  ConditionalInheritanceService._();
  static final ConditionalInheritanceService _instance = ConditionalInheritanceService._();
  factory ConditionalInheritanceService() => _instance;

  static const _rulesKey = 'inheritance_rules_v3';
  static const _requestsKey = 'inheritance_requests_v3';
  static const _maxRules = 100;
  static const _maxRequests = 1000;

  final SecurityService _security = SecurityService();
  final AdvancedSecurityLoggingService _logging = AdvancedSecurityLoggingService();

  /// Create a new inheritance rule
  Future<InheritanceRule> createRule({
    required String name,
    required String description,
    required ConditionType conditionType,
    required Map<String, dynamic> conditionData,
    required List<String> allowedHeirs,
    required List<String> allowedFolders,
    required List<String> allowedDocumentTypes,
    required AccessLevel accessLevel,
    DateTime? startDate,
    DateTime? endDate,
    int priority = 0,
  }) async {
    try {
      // Validate inputs
      _validateRuleInputs(
        name,
        description,
        conditionType,
        conditionData,
        allowedHeirs,
        allowedFolders,
        allowedDocumentTypes,
        accessLevel,
        startDate,
        endDate,
      );

      final rule = InheritanceRule(
        id: _generateId(),
        name: _security.sanitizeInput(name),
        description: _security.sanitizeInput(description),
        conditionType: conditionType,
        conditionData: conditionData,
        allowedHeirs: allowedHeirs,
        allowedFolders: allowedFolders,
        allowedDocumentTypes: allowedDocumentTypes,
        accessLevel: accessLevel,
        startDate: startDate,
        endDate: endDate,
        priority: priority,
        createdAt: DateTime.now(),
      );

      await _saveRule(rule);

      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_rule_created',
        businessData: {
          'ruleId': rule.id,
          'ruleName': rule.name,
          'conditionType': rule.conditionType.name,
          'accessLevel': rule.accessLevel.name,
          'allowedHeirs': rule.allowedHeirs.length,
        },
      );

      AppLogger.info('Inheritance rule created: ${rule.name}');
      return rule;
    } catch (e, st) {
      AppLogger.error('Failed to create inheritance rule', e, st);
      rethrow;
    }
  }

  /// Evaluate inheritance access for an heir
  Future<AccessResult> evaluateAccess({
    required String heirId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final rules = await _getActiveRules();
      final applicableRules = rules.where((rule) => 
          rule.allowedHeirs.contains(heirId) && 
          _isRuleApplicable(rule, context)).toList();

      if (applicableRules.isEmpty) {
        return const AccessResult(
          granted: false,
          accessLevel: AccessLevel.none,
          reason: 'No applicable inheritance rules found',
        );
      }

      // Sort rules by priority (higher priority first)
      applicableRules.sort((a, b) => b.priority.compareTo(a.priority));

      // Evaluate conditions and determine access
      final grantedRules = <InheritanceRule>[];
      final allAllowedFolders = <String>{};
      final allAllowedDocumentTypes = <String>{};
      AccessLevel highestAccess = AccessLevel.none;

      for (final rule in applicableRules) {
        if (await _evaluateCondition(rule, context)) {
          grantedRules.add(rule);
          allAllowedFolders.addAll(rule.allowedFolders);
          allAllowedDocumentTypes.addAll(rule.allowedDocumentTypes);
          
          // Determine highest access level
          if (rule.accessLevel.index > highestAccess.index) {
            highestAccess = rule.accessLevel;
          }
        }
      }

      final granted = grantedRules.isNotEmpty;
      final reason = granted 
          ? 'Access granted based on ${grantedRules.length} rule(s)'
          : 'Conditions not met for applicable rules';

      final result = AccessResult(
        granted: granted,
        accessLevel: highestAccess,
        allowedFolders: allAllowedFolders.toList(),
        allowedDocumentTypes: allAllowedDocumentTypes.toList(),
        appliedRules: grantedRules,
        reason: reason,
        metadata: {
          'heirId': heirId,
          'evaluatedAt': DateTime.now().toIso8601String(),
          'totalRules': rules.length,
          'applicableRules': applicableRules.length,
          'grantedRules': grantedRules.length,
        },
      );

      // Log access evaluation
      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_access_evaluated',
        businessData: {
          'heirId': heirId,
          'granted': granted,
          'accessLevel': highestAccess.name,
          'appliedRules': grantedRules.length,
        },
      );

      return result;
    } catch (e, st) {
      AppLogger.error('Failed to evaluate inheritance access', e, st);
      return const AccessResult(
        granted: false,
        accessLevel: AccessLevel.none,
        reason: 'Error during access evaluation',
      );
    }
  }

  /// Submit inheritance request
  Future<InheritanceRequest> submitRequest({
    required String heirId,
    required List<String> ruleIds,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      final request = InheritanceRequest(
        id: _generateId(),
        heirId: heirId,
        ruleIds: ruleIds,
        requestData: requestData,
        status: InheritanceStatus.pending,
        requestedAt: DateTime.now(),
      );

      await _saveRequest(request);

      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_request_submitted',
        businessData: {
          'requestId': request.id,
          'heirId': heirId,
          'ruleIds': ruleIds,
          'requestData': requestData,
        },
      );

      AppLogger.info('Inheritance request submitted: ${request.id}');
      return request;
    } catch (e, st) {
      AppLogger.error('Failed to submit inheritance request', e, st);
      rethrow;
    }
  }

  /// Approve inheritance request
  Future<bool> approveRequest({
    required String requestId,
    required String reviewedBy,
    Map<String, dynamic>? reviewData,
  }) async {
    try {
      final request = await _getRequest(requestId);
      if (request == null) {
        throw ArgumentError('Request not found');
      }

      if (request.status != InheritanceStatus.pending) {
        throw StateError('Request is not pending');
      }

      final updatedRequest = InheritanceRequest(
        id: request.id,
        heirId: request.heirId,
        ruleIds: request.ruleIds,
        requestData: request.requestData,
        status: InheritanceStatus.approved,
        requestedAt: request.requestedAt,
        reviewedAt: DateTime.now(),
        reviewedBy: reviewedBy,
        reviewData: reviewData,
      );

      await _saveRequest(updatedRequest);

      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_request_approved',
        businessData: {
          'requestId': requestId,
          'heirId': request.heirId,
          'reviewedBy': reviewedBy,
        },
      );

      AppLogger.info('Inheritance request approved: $requestId');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to approve inheritance request', e, st);
      return false;
    }
  }

  /// Reject inheritance request
  Future<bool> rejectRequest({
    required String requestId,
    required String reviewedBy,
    required String reason,
    Map<String, dynamic>? reviewData,
  }) async {
    try {
      final request = await _getRequest(requestId);
      if (request == null) {
        throw ArgumentError('Request not found');
      }

      if (request.status != InheritanceStatus.pending) {
        throw StateError('Request is not pending');
      }

      final updatedRequest = InheritanceRequest(
        id: request.id,
        heirId: request.heirId,
        ruleIds: request.ruleIds,
        requestData: request.requestData,
        status: InheritanceStatus.rejected,
        rejectionReason: reason,
        requestedAt: request.requestedAt,
        reviewedAt: DateTime.now(),
        reviewedBy: reviewedBy,
        reviewData: reviewData,
      );

      await _saveRequest(updatedRequest);

      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_request_rejected',
        businessData: {
          'requestId': requestId,
          'heirId': request.heirId,
          'reviewedBy': reviewedBy,
          'reason': reason,
        },
      );

      AppLogger.info('Inheritance request rejected: $requestId');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to reject inheritance request', e, st);
      return false;
    }
  }

  /// Get all inheritance rules
  Future<List<InheritanceRule>> getRules({bool includeInactive = false}) async {
    try {
      final rules = await _loadRules();
      
      if (!includeInactive) {
        return rules.where((rule) => rule.isActive).toList();
      }
      
      return rules;
    } catch (e, st) {
      AppLogger.error('Failed to get inheritance rules', e, st);
      return [];
    }
  }

  /// Get inheritance requests
  Future<List<InheritanceRequest>> getRequests({
    String? heirId,
    InheritanceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final requests = await _loadRequests();
      
      var filteredRequests = requests;
      
      if (heirId != null) {
        filteredRequests = requests.where((r) => r.heirId == heirId).toList();
      }
      
      if (status != null) {
        filteredRequests = filteredRequests.where((r) => r.status == status).toList();
      }
      
      if (startDate != null) {
        filteredRequests = filteredRequests.where((r) => r.requestedAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        filteredRequests = filteredRequests.where((r) => r.requestedAt.isBefore(endDate)).toList();
      }
      
      // Sort by requested date descending and limit
      filteredRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      
      return filteredRequests.take(limit).toList();
    } catch (e, st) {
      AppLogger.error('Failed to get inheritance requests', e, st);
      return [];
    }
  }

  /// Update inheritance rule
  Future<bool> updateRule(InheritanceRule rule) async {
    try {
      final updatedRule = rule.copyWith(lastModified: DateTime.now());
      await _saveRule(updatedRule);

      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_rule_updated',
        businessData: {
          'ruleId': rule.id,
          'ruleName': rule.name,
        },
      );

      AppLogger.info('Inheritance rule updated: ${rule.name}');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to update inheritance rule', e, st);
      return false;
    }
  }

  /// Delete inheritance rule
  Future<bool> deleteRule(String ruleId) async {
    try {
      final rules = await _loadRules();
      final filteredRules = rules.where((r) => r.id != ruleId).toList();
      
      await _saveRules(filteredRules);

      await _logging.logBusinessEvent(
        userId: 'current_user',
        event: 'inheritance_rule_deleted',
        businessData: {'ruleId': ruleId},
      );

      AppLogger.info('Inheritance rule deleted: $ruleId');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to delete inheritance rule', e, st);
      return false;
    }
  }

  /// Get inheritance statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final rules = await _loadRules();
      final requests = await _loadRequests();

      final activeRules = rules.where((r) => r.isActive).length;
      final pendingRequests = requests.where((r) => r.status == InheritanceStatus.pending).length;
      final approvedRequests = requests.where((r) => r.status == InheritanceStatus.approved).length;
      final rejectedRequests = requests.where((r) => r.status == InheritanceStatus.rejected).length;

      final rulesByType = <String, int>{};
      final rulesByAccessLevel = <String, int>{};

      for (final rule in rules) {
        // Count by condition type
        final typeName = rule.conditionType.name;
        rulesByType[typeName] = (rulesByType[typeName] ?? 0) + 1;

        // Count by access level
        final accessName = rule.accessLevel.name;
        rulesByAccessLevel[accessName] = (rulesByAccessLevel[accessName] ?? 0) + 1;
      }

      return {
        'totalRules': rules.length,
        'activeRules': activeRules,
        'totalRequests': requests.length,
        'pendingRequests': pendingRequests,
        'approvedRequests': approvedRequests,
        'rejectedRequests': rejectedRequests,
        'rulesByType': rulesByType,
        'rulesByAccessLevel': rulesByAccessLevel,
        'approvalRate': requests.isNotEmpty ? (approvedRequests / requests.length) * 100 : 0.0,
      };
    } catch (e, st) {
      AppLogger.error('Failed to get inheritance statistics', e, st);
      return {};
    }
  }

  /// Private methods

  void _validateRuleInputs(
    String name,
    String description,
    ConditionType conditionType,
    Map<String, dynamic> conditionData,
    List<String> allowedHeirs,
    List<String> allowedFolders,
    List<String> allowedDocumentTypes,
    AccessLevel accessLevel,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (name.isEmpty) {
      throw ArgumentError('Rule name cannot be empty');
    }

    if (description.isEmpty) {
      throw ArgumentError('Rule description cannot be empty');
    }

    if (allowedHeirs.isEmpty) {
      throw ArgumentError('At least one heir must be specified');
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError('Start date cannot be after end date');
    }

    // Validate condition data based on type
    _validateConditionData(conditionType, conditionData);
  }

  void _validateConditionData(ConditionType type, Map<String, dynamic> data) {
    switch (type) {
      case ConditionType.time_based:
        if (!data.containsKey('startTime') || !data.containsKey('endTime')) {
          throw ArgumentError('Time-based condition requires startTime and endTime');
        }
        break;
      case ConditionType.event_based:
        if (!data.containsKey('eventType')) {
          throw ArgumentError('Event-based condition requires eventType');
        }
        break;
      case ConditionType.location_based:
        if (!data.containsKey('allowedLocations') || !data.containsKey('currentLocation')) {
          throw ArgumentError('Location-based condition requires allowedLocations and currentLocation');
        }
        break;
      case ConditionType.approval_based:
        if (!data.containsKey('requiredApprovers')) {
          throw ArgumentError('Approval-based condition requires requiredApprovers');
        }
        break;
      case ConditionType.custom:
        if (!data.containsKey('customCondition')) {
          throw ArgumentError('Custom condition requires customCondition');
        }
        break;
    }
  }

  bool _isRuleApplicable(InheritanceRule rule, Map<String, dynamic>? context) {
    final now = DateTime.now();

    // Check date range
    if (rule.startDate != null && now.isBefore(rule.startDate!)) {
      return false;
    }

    if (rule.endDate != null && now.isAfter(rule.endDate!)) {
      return false;
    }

    return true;
  }

  Future<bool> _evaluateCondition(InheritanceRule rule, Map<String, dynamic>? context) async {
    switch (rule.conditionType) {
      case ConditionType.time_based:
        return _evaluateTimeCondition(rule.conditionData);
      case ConditionType.event_based:
        return await _evaluateEventCondition(rule.conditionData, context);
      case ConditionType.location_based:
        return _evaluateLocationCondition(rule.conditionData, context);
      case ConditionType.approval_based:
        return await _evaluateApprovalCondition(rule.conditionData, context);
      case ConditionType.custom:
        return await _evaluateCustomCondition(rule.conditionData, context);
    }
  }

  bool _evaluateTimeCondition(Map<String, dynamic> data) {
    final now = DateTime.now();
    final startTime = DateTime.parse(data['startTime'] as String);
    final endTime = DateTime.parse(data['endTime'] as String);

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Future<bool> _evaluateEventCondition(Map<String, dynamic> data, Map<String, dynamic>? context) async {
    final requiredEvent = data['eventType'] as String;
    
    if (context == null || !context.containsKey('events')) {
      return false;
    }

    final events = context['events'] as List<dynamic>;
    return events.any((event) => event['type'] == requiredEvent);
  }

  bool _evaluateLocationCondition(Map<String, dynamic> data, Map<String, dynamic>? context) {
    final allowedLocations = data['allowedLocations'] as List<dynamic>;
    final currentLocation = data['currentLocation'] as String?;

    if (currentLocation == null) return false;

    return allowedLocations.contains(currentLocation);
  }

  Future<bool> _evaluateApprovalCondition(Map<String, dynamic> data, Map<String, dynamic>? context) async {
    final requiredApprovers = data['requiredApprovers'] as List<dynamic>;
    
    if (context == null || !context.containsKey('approvals')) {
      return false;
    }

    final approvals = context['approvals'] as List<dynamic>;
    final approvedBy = approvals.map((a) => a['approver'] as String).toSet();

    return requiredApprovers.every((approver) => approvedBy.contains(approver));
  }

  Future<bool> _evaluateCustomCondition(Map<String, dynamic> data, Map<String, dynamic>? context) async {
    // Custom condition evaluation would be implemented based on specific requirements
    // For now, return true as placeholder
    return true;
  }

  Future<List<InheritanceRule>> _loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getStringList(_rulesKey) ?? [];
      
      return rulesJson
          .map((json) => InheritanceRule.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to load inheritance rules', e, st);
      return [];
    }
  }

  Future<void> _saveRules(List<InheritanceRule> rules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = rules.map((rule) => jsonEncode(rule.toJson())).toList();
      
      await prefs.setStringList(_rulesKey, rulesJson);
    } catch (e, st) {
      AppLogger.error('Failed to save inheritance rules', e, st);
    }
  }

  Future<void> _saveRule(InheritanceRule rule) async {
    try {
      final rules = await _loadRules();
      rules.add(rule);
      
      // Maintain size limit
      if (rules.length > _maxRules) {
        rules.removeRange(0, rules.length - _maxRules);
      }
      
      await _saveRules(rules);
    } catch (e, st) {
      AppLogger.error('Failed to save inheritance rule', e, st);
    }
  }

  Future<List<InheritanceRule>> _getActiveRules() async {
    final rules = await _loadRules();
    return rules.where((rule) => rule.isActive).toList();
  }

  Future<List<InheritanceRequest>> _loadRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList(_requestsKey) ?? [];
      
      return requestsJson
          .map((json) => InheritanceRequest.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to load inheritance requests', e, st);
      return [];
    }
  }

  Future<void> _saveRequests(List<InheritanceRequest> requests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = requests.map((request) => jsonEncode(request.toJson())).toList();
      
      await prefs.setStringList(_requestsKey, requestsJson);
    } catch (e, st) {
      AppLogger.error('Failed to save inheritance requests', e, st);
    }
  }

  Future<void> _saveRequest(InheritanceRequest request) async {
    try {
      final requests = await _loadRequests();
      requests.add(request);
      
      // Maintain size limit
      if (requests.length > _maxRequests) {
        requests.removeRange(0, requests.length - _maxRequests);
      }
      
      await _saveRequests(requests);
    } catch (e, st) {
      AppLogger.error('Failed to save inheritance request', e, st);
    }
  }

  Future<InheritanceRequest?> _getRequest(String requestId) async {
    try {
      final requests = await _loadRequests();
      return requests.where((r) => r.id == requestId).firstOrNull;
    } catch (e, st) {
      AppLogger.error('Failed to get inheritance request', e, st);
      return null;
    }
  }

  String _generateId() {
    return 'inh_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
