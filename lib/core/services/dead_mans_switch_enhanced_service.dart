// Enhanced Dead Man's Switch Service with Supabase Integration
// Copyright © 2026 Aeternal Heritage. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

class DeadMansSwitchEnhancedService {
  static DeadMansSwitchEnhancedService? _instance;
  static DeadMansSwitchEnhancedService get instance => _instance ??= DeadMansSwitchEnhancedService._();

  DeadMansSwitchEnhancedService._();

  final Uuid _uuid = const Uuid();
  Timer? _inactivityTimer;
  Timer? _gracePeriodTimer;
  
  static const Duration _checkInterval = Duration(minutes: 5);
  static const Duration _gracePeriod = Duration(hours: 48);

  // Initialize enhanced DMS service
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      
      // Start periodic inactivity check
      _startInactivityCheck();
      
      print('Enhanced Dead Man\'s Switch service initialized');
    } catch (e) {
      print('Failed to initialize enhanced DMS service: $e');
      rethrow;
    }
  }

  // Start periodic inactivity check
  void _startInactivityCheck() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(_checkInterval, (_) {
      _checkUserInactivity();
    });
  }

  // Check for inactive users
  Future<void> _checkUserInactivity() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get all active DMS configurations
      final response = await supabase
          .from('dead_mans_switch')
          .select()
          .eq('is_active', true);
      
      final dmsConfigs = List<Map<String, dynamic>>.from(response);
      
      for (final config in dmsConfigs) {
        await _processUserInactivity(config);
      }
    } catch (e) {
      print('Check user inactivity error: $e');
    }
  }

  // Process individual user inactivity
  Future<void> _processUserInactivity(Map<String, dynamic> config) async {
    try {
      final userId = config['user_id'];
      final lastCheckIn = DateTime.parse(config['last_check_in']);
      final maxInactivityDays = config['max_inactivity_days'] ?? 30;
      final now = DateTime.now();
      
      final daysSinceLastCheckIn = now.difference(lastCheckIn).inDays;
      
      print('User $userId: Last check-in $daysSinceLastCheckIn days ago');
      
      if (daysSinceLastCheckIn >= maxInactivityDays) {
        await _startGracePeriod(userId, config);
      } else if (daysSinceLastCheckIn >= maxInactivityDays - 7) {
        // Send warning email 7 days before deadline
        await _sendWarningEmail(userId, config, daysSinceLastCheckIn);
      }
    } catch (e) {
      print('Process user inactivity error: $e');
    }
  }

  // Start grace period for user
  Future<void> _startGracePeriod(String userId, Map<String, dynamic> config) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if grace period already started
      if (config['grace_period_started'] != null) {
        final graceStarted = DateTime.parse(config['grace_period_started']);
        final hoursInGracePeriod = DateTime.now().difference(graceStarted).inHours;
        
        if (hoursInGracePeriod >= _gracePeriod.inHours) {
          // Grace period expired, send files to heirs
          await _sendFilesToHeirs(userId, config);
          return;
        }
        
        // Send reminder email
        await _sendGracePeriodReminder(userId, config, hoursInGracePeriod);
        return;
      }
      
      // Start grace period
      await supabase
          .from('dead_mans_switch')
          .update({
            'grace_period_started': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      // Send grace period notification
      await _sendGracePeriodNotification(userId, config);
      
      // Start grace period timer
      _startGracePeriodTimer(userId, config);
      
      print('Grace period started for user: $userId');
    } catch (e) {
      print('Start grace period error: $e');
    }
  }

  // Start grace period timer
  void _startGracePeriodTimer(String userId, Map<String, dynamic> config) {
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(_gracePeriod, () async {
      await _sendFilesToHeirs(userId, config);
    });
  }

  // Send files to heirs
  Future<void> _sendFilesToHeirs(String userId, Map<String, dynamic> config) async {
    try {
      print('Sending files to heirs for user: $userId');
      
      // Get user files
      final files = await _getUserFiles(userId);
      final heirs = await _getUserHeirs(userId);
      
      // Send email to each heir
      for (final heir in heirs) {
        await _sendInheritanceEmail(userId, heir, files, config);
      }
      
      // Mark DMS as triggered
      await _markDmsTriggered(userId);
      
      print('Files sent to heirs for user: $userId');
    } catch (e) {
      print('Send files to heirs error: $e');
    }
  }

  // Get user files
  Future<List<Map<String, dynamic>>> _getUserFiles(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('vault_files')
          .select()
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get user files error: $e');
      return [];
    }
  }

  // Get user heirs
  Future<List<Map<String, dynamic>>> _getUserHeirs(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('heirs')
          .select()
          .eq('user_id', userId)
          .eq('is_verified', true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get user heirs error: $e');
      return [];
    }
  }

  // Send inheritance email to heir
  Future<void> _sendInheritanceEmail(
    String userId,
    Map<String, dynamic> heir,
    List<Map<String, dynamic>> files,
    Map<String, dynamic> config,
  ) async {
    try {
      final heirEmail = heir['email'];
      final heirName = heir['full_name'];
      
      // Generate secure download links
      final downloadLinks = <String>[];
      for (final file in files) {
        final link = await _generateSecureDownloadLink(file['id'], userId);
        downloadLinks.add('${file['file_name']}: $link');
      }
      
      // Send email using your email service
      final emailData = {
        'to': heirEmail,
        'subject': 'Important: Digital Vault Heritage - Inheritance Notification',
        'template': 'inheritance_notification',
        'data': {
          'heir_name': heirName,
          'owner_name': config['owner_name'] ?? 'Digital Vault Heritage User',
          'download_links': downloadLinks.join('\n'),
          'message': config['custom_message'] ?? '',
          'date': DateTime.now().toIso8601String(),
        },
      };
      
      await _sendEmail(emailData);
      
      print('Inheritance email sent to: $heirEmail');
    } catch (e) {
      print('Send inheritance email error: $e');
    }
  }

  // Generate secure download link
  Future<String> _generateSecureDownloadLink(String fileId, String userId) async {
    try {
      // Generate temporary access token
      final token = _uuid.v4();
      final expiresAt = DateTime.now().add(Duration(days: 7));
      
      // Store token in database
      final supabase = Supabase.instance.client;
      await supabase
          .from('download_tokens')
          .insert({
            'id': _uuid.v4(),
            'file_id': fileId,
            'user_id': userId,
            'token': token,
            'expires_at': expiresAt.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
      
      // Generate download URL
      final baseUrl = dotenv.env['APP_BASE_URL'] ?? 'https://your-app.com';
      return '$baseUrl/download?token=$token';
    } catch (e) {
      print('Generate download link error: $e');
      return '';
    }
  }

  // Send warning email
  Future<void> _sendWarningEmail(
    String userId,
    Map<String, dynamic> config,
    int daysSinceLastCheckIn,
  ) async {
    try {
      final maxInactivityDays = config['max_inactivity_days'] ?? 30;
      final daysRemaining = maxInactivityDays - daysSinceLastCheckIn;
      
      final emailData = {
        'to': await _getUserEmail(userId),
        'subject': 'Digital Vault Heritage - Check-in Reminder',
        'template': 'check_in_reminder',
        'data': {
          'days_remaining': daysRemaining,
          'last_check_in': config['last_check_in'],
          'check_in_url': '${dotenv.env['APP_BASE_URL']}/check-in',
        },
      };
      
      await _sendEmail(emailData);
      
      print('Warning email sent to user: $userId');
    } catch (e) {
      print('Send warning email error: $e');
    }
  }

  // Send grace period notification
  Future<void> _sendGracePeriodNotification(
    String userId,
    Map<String, dynamic> config,
  ) async {
    try {
      final emailData = {
        'to': await _getUserEmail(userId),
        'subject': 'Digital Vault Heritage - Grace Period Started',
        'template': 'grace_period_started',
        'data': {
          'grace_period_hours': _gracePeriod.inHours,
          'grace_period_end': DateTime.now().add(_gracePeriod).toIso8601String(),
          'cancel_url': '${dotenv.env['APP_BASE_URL']}/cancel-grace-period',
        },
      };
      
      await _sendEmail(emailData);
      
      print('Grace period notification sent to user: $userId');
    } catch (e) {
      print('Send grace period notification error: $e');
    }
  }

  // Send grace period reminder
  Future<void> _sendGracePeriodReminder(
    String userId,
    Map<String, dynamic> config,
    int hoursInGracePeriod,
  ) async {
    try {
      final hoursRemaining = _gracePeriod.inHours - hoursInGracePeriod;
      
      final emailData = {
        'to': await _getUserEmail(userId),
        'subject': 'Digital Vault Heritage - Grace Period Reminder',
        'template': 'grace_period_reminder',
        'data': {
          'hours_remaining': hoursRemaining,
          'grace_period_end': DateTime.now().add(Duration(hours: hoursRemaining)).toIso8601String(),
          'cancel_url': '${dotenv.env['APP_BASE_URL']}/cancel-grace-period',
        },
      };
      
      await _sendEmail(emailData);
      
      print('Grace period reminder sent to user: $userId');
    } catch (e) {
      print('Send grace period reminder error: $e');
    }
  }

  // Mark DMS as triggered
  Future<void> _markDmsTriggered(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('dead_mans_switch')
          .update({
            'is_active': false,
            'triggered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      print('DMS marked as triggered for user: $userId');
    } catch (e) {
      print('Mark DMS triggered error: $e');
    }
  }

  // Update user check-in
  Future<bool> updateCheckIn(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('dead_mans_switch')
          .update({
            'last_check_in': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      print('Check-in updated for user: $userId');
      return true;
    } catch (e) {
      print('Update check-in error: $e');
      return false;
    }
  }

  // Cancel grace period
  Future<bool> cancelGracePeriod(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('dead_mans_switch')
          .update({
            'grace_period_started': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      print('Grace period cancelled for user: $userId');
      return true;
    } catch (e) {
      print('Cancel grace period error: $e');
      return false;
    }
  }

  // Get user email
  Future<String> _getUserEmail(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('profiles')
          .select('email')
          .eq('id', userId)
          .single();
      
      return response['email'] ?? '';
    } catch (e) {
      print('Get user email error: $e');
      return '';
    }
  }

  // Send email (placeholder for your email service)
  Future<void> _sendEmail(Map<String, dynamic> emailData) async {
    try {
      // TODO: Implement your email service integration
      // This could be SendGrid, AWS SES, or any email service
      print('Email data: ${jsonEncode(emailData)}');
      
      // Example implementation:
      // final response = await http.post(
      //   Uri.parse('https://api.email-service.com/send'),
      //   headers: {'Authorization': 'Bearer ${dotenv.env['EMAIL_API_KEY']}'},
      //   body: jsonEncode(emailData),
      // );
      
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to send email');
      // }
    } catch (e) {
      print('Send email error: $e');
      rethrow;
    }
  }

  // Configure DMS for user
  Future<bool> configureDeadMansSwitch(
    String userId,
    Map<String, dynamic> config,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('dead_mans_switch')
          .upsert({
            'id': _uuid.v4(),
            'user_id': userId,
            'is_active': config['is_active'] ?? false,
            'max_inactivity_days': config['max_inactivity_days'] ?? 30,
            'last_check_in': DateTime.now().toIso8601String(),
            'heirs': jsonEncode(config['heirs'] ?? []),
            'custom_message': config['custom_message'] ?? '',
            'owner_name': config['owner_name'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      print('DMS configured for user: $userId');
      return true;
    } catch (e) {
      print('Configure DMS error: $e');
      return false;
    }
  }

  // Get DMS configuration
  Future<Map<String, dynamic>?> getDmsConfiguration(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('dead_mans_switch')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Get DMS configuration error: $e');
      return null;
    }
  }

  // Dispose timers
  void dispose() {
    _inactivityTimer?.cancel();
    _gracePeriodTimer?.cancel();
  }
}
