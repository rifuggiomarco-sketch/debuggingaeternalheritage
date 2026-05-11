// v2.5 - Subscription & Pricing Service with Stripe Integration
// Manages subscription tiers, payments, and license activation
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger.dart';
import 'security_service.dart';

enum SubscriptionTier {
  free('free', 'Free', 0, 'basic_features'),
  premium('premium', 'Premium', 9999, 'all_features'),
  lifetime('lifetime', 'Lifetime', 99999, 'lifetime_access');

  const SubscriptionTier(this.id, this.displayName, this.price, this.features);
  final String id;
  final String displayName;
  final int price; // in cents
  final String features;
}

enum SubscriptionStatus {
  active,
  canceled,
  past_due,
  incomplete,
  incomplete_expired,
  trialing,
  unpaid,
  free,
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? canceledAt;
  final DateTime? trialEnd;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Subscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.canceledAt,
    this.trialEnd,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.createdAt,
    required this.updatedAt,
  });
  
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;
  bool get isExpired => currentPeriodEnd != null && DateTime.now().isAfter(currentPeriodEnd!);
  bool get isCanceled => canceledAt != null;
  bool get isPaid => tier != SubscriptionTier.free;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'tier': tier.id,
    'status': status.name,
    'currentPeriodStart': currentPeriodStart?.toIso8601String(),
    'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    'canceledAt': canceledAt?.toIso8601String(),
    'trialEnd': trialEnd?.toIso8601String(),
    'stripeCustomerId': stripeCustomerId,
    'stripeSubscriptionId': stripeSubscriptionId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    userId: json['userId'] as String,
    tier: SubscriptionTier.values.firstWhere((t) => t.id == json['tier']),
    status: SubscriptionStatus.values.firstWhere((s) => s.name == json['status']),
    currentPeriodStart: json['currentPeriodStart'] != null 
        ? DateTime.parse(json['currentPeriodStart'] as String) 
        : null,
    currentPeriodEnd: json['currentPeriodEnd'] != null 
        ? DateTime.parse(json['currentPeriodEnd'] as String) 
        : null,
    canceledAt: json['canceledAt'] != null 
        ? DateTime.parse(json['canceledAt'] as String) 
        : null,
    trialEnd: json['trialEnd'] != null 
        ? DateTime.parse(json['trialEnd'] as String) 
        : null,
    stripeCustomerId: json['stripeCustomerId'] as String?,
    stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class StripeWebhookEvent {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime created;
  
  StripeWebhookEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.created,
  });
  
  factory StripeWebhookEvent.fromJson(Map<String, dynamic> json) => StripeWebhookEvent(
    id: json['id'] as String,
    type: json['type'] as String,
    data: json['data'] as Map<String, dynamic>,
    created: DateTime.fromMillisecondsSinceEpoch(json['created'] as int),
  );
}

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  static const _subscriptionKey = 'user_subscription';

  // Stripe configuration - should be environment variables in production
  static const String _stripeSecretKey = 'sk_test_...'; // Replace with actual key
  static const String _baseUrl = 'https://api.stripe.com/v1';
  
  final SecurityService _security = SecurityService();
  final Map<String, String> _stripePrices = {
    'premium_monthly': 'price_1PremiumMonthly',
    'premium_yearly': 'price_1PremiumYearly',
    'lifetime': 'price_1Lifetime',
  };
  
  /// Initialize subscription service
  Future<void> initialize() async {
    try {
      await _validateSubscription();
      AppLogger.info('Subscription service initialized');
    } catch (e, st) {
      AppLogger.error('Failed to initialize subscription service', e, st);
    }
  }
  
  /// Get current subscription
  Future<Subscription?> getCurrentSubscription() async {
    try {
      final subscriptionJson = await _storage.read(key: _subscriptionKey);
      if (subscriptionJson != null) {
        return Subscription.fromJson(jsonDecode(subscriptionJson) as Map<String, dynamic>);
      }
    } catch (e, st) {
      AppLogger.error('Failed to load subscription', e, st);
    }
    return null;
  }
  
  /// Create or update subscription
  Future<Subscription> createSubscription(
    String userId,
    SubscriptionTier tier, {
    String? paymentMethodId,
    String? stripeCustomerId,
  }) async {
    try {
      // Validate input
      userId = _security.sanitizeInput(userId);
      
      if (tier == SubscriptionTier.free) {
        return await _createFreeSubscription(userId);
      }
      
      // Create Stripe customer if not exists
      final customerId = stripeCustomerId ?? await _createStripeCustomer(userId);
      
      // Create Stripe subscription
      final stripeSubscription = await _createStripeSubscription(
        customerId,
        tier,
        paymentMethodId,
      );
      
      // Create local subscription
      final subscription = Subscription(
        id: _generateId(),
        userId: userId,
        tier: tier,
        status: SubscriptionStatus.active,
        currentPeriodStart: DateTime.fromMillisecondsSinceEpoch(
          stripeSubscription['current_period_start'] * 1000,
        ),
        currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(
          stripeSubscription['current_period_end'] * 1000,
        ),
        stripeCustomerId: customerId,
        stripeSubscriptionId: stripeSubscription['id'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _saveSubscription(subscription);
      
      await _security.logSecurityEvent(
        'subscription_created',
        userId: userId,
        metadata: {
          'tier': tier.id,
          'stripeSubscriptionId': stripeSubscription['id'],
        },
      );
      
      AppLogger.info('Subscription created for user: $userId');
      return subscription;
    } catch (e, st) {
      AppLogger.error('Failed to create subscription', e, st);
      rethrow;
    }
  }
  
  /// Create free subscription
  Future<Subscription> _createFreeSubscription(String userId) async {
    final subscription = Subscription(
      id: _generateId(),
      userId: userId,
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.free,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _saveSubscription(subscription);
    return subscription;
  }
  
  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null || subscription.id != subscriptionId) {
        throw ArgumentError('Subscription not found');
      }
      
      // Cancel in Stripe
      if (subscription.stripeSubscriptionId != null) {
        await _cancelStripeSubscription(subscription.stripeSubscriptionId!);
      }
      
      // Update local subscription
      final canceledSubscription = subscription.copyWith(
        status: SubscriptionStatus.canceled,
        canceledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _saveSubscription(canceledSubscription);
      
      await _security.logSecurityEvent(
        'subscription_canceled',
        userId: subscription.userId,
        metadata: {'subscriptionId': subscriptionId},
      );
      
      AppLogger.info('Subscription canceled: $subscriptionId');
    } catch (e, st) {
      AppLogger.error('Failed to cancel subscription', e, st);
      rethrow;
    }
  }
  
  /// Handle Stripe webhook
  Future<void> handleStripeWebhook(String payload, String signature) async {
    try {
      // Verify webhook signature
      if (!_verifyWebhookSignature(payload, signature)) {
        throw SecurityViolationException('Invalid webhook signature', SecurityViolationType.suspiciousActivity);
      }
      
      final event = StripeWebhookEvent.fromJson(jsonDecode(payload) as Map<String, dynamic>);
      
      switch (event.type) {
        case 'invoice.payment_succeeded':
          await _handlePaymentSucceeded(event);
          break;
        case 'invoice.payment_failed':
          await _handlePaymentFailed(event);
          break;
        case 'customer.subscription.deleted':
          await _handleSubscriptionDeleted(event);
          break;
        case 'customer.subscription.updated':
          await _handleSubscriptionUpdated(event);
          break;
        default:
          AppLogger.info('Unhandled webhook event: ${event.type}');
      }
      
      await _security.logSecurityEvent(
        'stripe_webhook_processed',
        metadata: {'eventType': event.type},
      );
    } catch (e, st) {
      AppLogger.error('Failed to handle Stripe webhook', e, st);
      rethrow;
    }
  }
  
  /// Check if user has access to premium features
  Future<bool> hasPremiumAccess(String userId) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;
      
      if (subscription.tier == SubscriptionTier.lifetime) return true;
      
      return subscription.isActive && !subscription.isExpired;
    } catch (e, st) {
      AppLogger.error('Failed to check premium access', e, st);
      return false;
    }
  }
  
  /// Get available subscription tiers
  List<SubscriptionTier> getAvailableTiers() {
    return SubscriptionTier.values;
  }
  
  /// Get pricing information
  Map<String, dynamic> getPricingInfo() {
    return {
      'tiers': SubscriptionTier.values.map((tier) => {
        'id': tier.id,
        'name': tier.displayName,
        'price': tier.price,
        'features': tier.features,
      }).toList(),
      'currency': 'USD',
      'billingInterval': 'monthly/yearly/lifetime',
    };
  }
  
  /// Create Stripe customer
  Future<String> _createStripeCustomer(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'description': 'Customer for user: $userId',
          'metadata[user_id]': userId,
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to create Stripe customer: ${response.body}');
      }
      
      final customer = jsonDecode(response.body) as Map<String, dynamic>;
      return customer['id'] as String;
    } catch (e, st) {
      AppLogger.error('Failed to create Stripe customer', e, st);
      rethrow;
    }
  }
  
  /// Create Stripe subscription
  Future<Map<String, dynamic>> _createStripeSubscription(
    String customerId,
    SubscriptionTier tier,
    String? paymentMethodId,
  ) async {
    try {
      final priceId = _getPriceIdForTier(tier);
      
      final body = <String, String>{
        'customer': customerId,
        'items[0][price]': priceId,
      };
      
      if (paymentMethodId != null) {
        body['default_payment_method'] = paymentMethodId;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to create Stripe subscription: ${response.body}');
      }
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Failed to create Stripe subscription', e, st);
      rethrow;
    }
  }
  
  /// Cancel Stripe subscription
  Future<void> _cancelStripeSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel Stripe subscription: ${response.body}');
      }
    } catch (e, st) {
      AppLogger.error('Failed to cancel Stripe subscription', e, st);
      rethrow;
    }
  }
  
  /// Get price ID for subscription tier
  String _getPriceIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.premium:
        return _stripePrices['premium_yearly']!;
      case SubscriptionTier.lifetime:
        return _stripePrices['lifetime']!;
      default:
        throw ArgumentError('Invalid tier for paid subscription: ${tier.id}');
    }
  }
  
  /// Verify webhook signature
  bool _verifyWebhookSignature(String payload, String signature) {
    try {
      // In production, implement proper signature verification
      // using Stripe's signature verification method
      return signature.isNotEmpty && payload.isNotEmpty;
    } catch (e) {
      AppLogger.error('Webhook signature verification failed', e);
      return false;
    }
  }
  
  /// Handle payment succeeded webhook
  Future<void> _handlePaymentSucceeded(StripeWebhookEvent event) async {
    try {
      final subscriptionData = event.data['object'] as Map<String, dynamic>;
      final subscriptionId = subscriptionData['subscription'] as String?;
      
      if (subscriptionId != null) {
        final subscription = await getCurrentSubscription();
        if (subscription?.stripeSubscriptionId == subscriptionId) {
          final updatedSubscription = subscription!.copyWith(
            status: SubscriptionStatus.active,
            updatedAt: DateTime.now(),
          );
          await _saveSubscription(updatedSubscription);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to handle payment succeeded', e, st);
    }
  }
  
  /// Handle payment failed webhook
  Future<void> _handlePaymentFailed(StripeWebhookEvent event) async {
    try {
      final subscriptionData = event.data['object'] as Map<String, dynamic>;
      final subscriptionId = subscriptionData['subscription'] as String?;
      
      if (subscriptionId != null) {
        final subscription = await getCurrentSubscription();
        if (subscription?.stripeSubscriptionId == subscriptionId) {
          final updatedSubscription = subscription!.copyWith(
            status: SubscriptionStatus.past_due,
            updatedAt: DateTime.now(),
          );
          await _saveSubscription(updatedSubscription);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to handle payment failed', e, st);
    }
  }
  
  /// Handle subscription deleted webhook
  Future<void> _handleSubscriptionDeleted(StripeWebhookEvent event) async {
    try {
      final subscriptionData = event.data['object'] as Map<String, dynamic>;
      final subscriptionId = subscriptionData['id'] as String?;
      
      if (subscriptionId != null) {
        final subscription = await getCurrentSubscription();
        if (subscription?.stripeSubscriptionId == subscriptionId) {
          final updatedSubscription = subscription!.copyWith(
            status: SubscriptionStatus.canceled,
            canceledAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _saveSubscription(updatedSubscription);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to handle subscription deleted', e, st);
    }
  }
  
  /// Handle subscription updated webhook
  Future<void> _handleSubscriptionUpdated(StripeWebhookEvent event) async {
    try {
      final subscriptionData = event.data['object'] as Map<String, dynamic>;
      final subscriptionId = subscriptionData['id'] as String?;
      
      if (subscriptionId != null) {
        final subscription = await getCurrentSubscription();
        if (subscription?.stripeSubscriptionId == subscriptionId) {
          final status = _mapStripeStatus(subscriptionData['status'] as String);
          final updatedSubscription = subscription!.copyWith(
            status: status,
            currentPeriodStart: DateTime.fromMillisecondsSinceEpoch(
              subscriptionData['current_period_start'] * 1000,
            ),
            currentPeriodEnd: DateTime.fromMillisecondsSinceEpoch(
              subscriptionData['current_period_end'] * 1000,
            ),
            updatedAt: DateTime.now(),
          );
          await _saveSubscription(updatedSubscription);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to handle subscription updated', e, st);
    }
  }
  
  /// Map Stripe status to internal status
  SubscriptionStatus _mapStripeStatus(String stripeStatus) {
    switch (stripeStatus) {
      case 'active':
        return SubscriptionStatus.active;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'past_due':
        return SubscriptionStatus.past_due;
      case 'incomplete':
        return SubscriptionStatus.incomplete;
      case 'incomplete_expired':
        return SubscriptionStatus.incomplete_expired;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'unpaid':
        return SubscriptionStatus.unpaid;
      default:
        return SubscriptionStatus.active;
    }
  }
  
  /// Validate and update subscription status
  Future<void> _validateSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return;
      
      // Check if subscription needs validation with Stripe
      if (subscription.stripeSubscriptionId != null && subscription.isActive) {
        // In production, you would validate with Stripe API
        // For now, we'll just check local expiration
        if (subscription.isExpired) {
          final updatedSubscription = subscription.copyWith(
            status: SubscriptionStatus.past_due,
            updatedAt: DateTime.now(),
          );
          await _saveSubscription(updatedSubscription);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to validate subscription', e, st);
    }
  }
  
  /// Save subscription to secure storage
  Future<void> _saveSubscription(Subscription subscription) async {
    try {
      await _storage.write(
        key: _subscriptionKey,
        value: jsonEncode(subscription.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('Failed to save subscription', e, st);
    }
  }
  
  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random.secure().nextInt(10000).toString();
  }
}

// Extension for Subscription copyWith
extension SubscriptionCopyWith on Subscription {
  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? canceledAt,
    DateTime? trialEnd,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Subscription(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tier: tier ?? this.tier,
    status: status ?? this.status,
    currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
    currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
    canceledAt: canceledAt ?? this.canceledAt,
    trialEnd: trialEnd ?? this.trialEnd,
    stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
    stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
