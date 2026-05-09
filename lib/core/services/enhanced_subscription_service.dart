// v3.0 - Enhanced Subscription Service with Advanced Payment Flow and Business Automation
// Provides enterprise-grade subscription management with instant upgrades and comprehensive reporting
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger.dart';
import 'security_service.dart';
import 'advanced_security_logging_service.dart';

enum SubscriptionTierV3 {
  free('free', 'Free', 0, 'basic_features', 10, 1),
  premium('premium', 'Premium', 9999, 'all_features', 100, 5),
  lifetime('lifetime', 'Lifetime', 99999, 'lifetime_access', -1, -1);

  const SubscriptionTierV3(this.id, this.displayName, this.price, this.features, this.maxDocuments, this.maxHeirs);
  final String id;
  final String displayName;
  final int price; // in cents
  final String features;
  final int maxDocuments; // -1 for unlimited
  final int maxHeirs; // -1 for unlimited
}

enum BillingCycle {
  monthly,
  yearly,
  lifetime,
}

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  canceled,
  refunded,
  partially_refunded,
}

enum SubscriptionTransition {
  free_to_premium,
  premium_to_lifetime,
  lifetime_to_premium,
  premium_to_free,
  any_to_free,
  upgrade,
  downgrade,
  cancellation,
}

class EnhancedSubscription {
  final String id;
  final String userId;
  final SubscriptionTierV3 tier;
  final BillingCycle billingCycle;
  final PaymentStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final DateTime? canceledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? paymentMethodId;
  final Map<String, dynamic>? metadata;
  final List<SubscriptionTransition> transitionHistory;
  final bool autoRenew;
  final DateTime? lastPaymentDate;
  final int? failedPaymentAttempts;

  const EnhancedSubscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.billingCycle,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEnd,
    this.canceledAt,
    this.createdAt,
    this.updatedAt,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.paymentMethodId,
    this.metadata,
    this.transitionHistory = const [],
    this.autoRenew = true,
    this.lastPaymentDate,
    this.failedPaymentAttempts,
  });

  bool get isActive => status == PaymentStatus.succeeded && (currentPeriodEnd == null || DateTime.now().isBefore(currentPeriodEnd!));
  bool get isExpired => currentPeriodEnd != null && DateTime.now().isAfter(currentPeriodEnd!);
  bool get isCanceled => canceledAt != null;
  bool get isPaid => tier != SubscriptionTierV3.free;
  bool get isTrialActive => trialEnd != null && DateTime.now().isBefore(trialEnd!);
  bool get needsPayment => status == PaymentStatus.pending || status == PaymentStatus.failed;

  EnhancedSubscription copyWith({
    String? id,
    String? userId,
    SubscriptionTierV3? tier,
    BillingCycle? billingCycle,
    PaymentStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialEnd,
    DateTime? canceledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
    List<SubscriptionTransition>? transitionHistory,
    bool? autoRenew,
    DateTime? lastPaymentDate,
    int? failedPaymentAttempts,
  }) => EnhancedSubscription(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tier: tier ?? this.tier,
    billingCycle: billingCycle ?? this.billingCycle,
    status: status ?? this.status,
    currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
    currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
    trialEnd: trialEnd ?? this.trialEnd,
    canceledAt: canceledAt ?? this.canceledAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
    stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    metadata: metadata ?? this.metadata,
    transitionHistory: transitionHistory ?? this.transitionHistory,
    autoRenew: autoRenew ?? this.autoRenew,
    lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    failedPaymentAttempts: failedPaymentAttempts ?? this.failedPaymentAttempts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'tier': tier.id,
    'billingCycle': billingCycle.name,
    'status': status.name,
    'currentPeriodStart': currentPeriodStart?.toIso8601String(),
    'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    'trialEnd': trialEnd?.toIso8601String(),
    'canceledAt': canceledAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'stripeCustomerId': stripeCustomerId,
    'stripeSubscriptionId': stripeSubscriptionId,
    'paymentMethodId': paymentMethodId,
    'metadata': metadata,
    'transitionHistory': transitionHistory.map((t) => t.name).toList(),
    'autoRenew': autoRenew,
    'lastPaymentDate': lastPaymentDate?.toIso8601String(),
    'failedPaymentAttempts': failedPaymentAttempts,
  };

  factory EnhancedSubscription.fromJson(Map<String, dynamic> json) => EnhancedSubscription(
    id: json['id'] as String,
    userId: json['userId'] as String,
    tier: SubscriptionTierV3.values.firstWhere((t) => t.id == json['tier']),
    billingCycle: BillingCycle.values.firstWhere((b) => b.name == json['billingCycle']),
    status: PaymentStatus.values.firstWhere((s) => s.name == json['status']),
    currentPeriodStart: json['currentPeriodStart'] != null ? DateTime.parse(json['currentPeriodStart'] as String) : null,
    currentPeriodEnd: json['currentPeriodEnd'] != null ? DateTime.parse(json['currentPeriodEnd'] as String) : null,
    trialEnd: json['trialEnd'] != null ? DateTime.parse(json['trialEnd'] as String) : null,
    canceledAt: json['canceledAt'] != null ? DateTime.parse(json['canceledAt'] as String) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    stripeCustomerId: json['stripeCustomerId'] as String?,
    stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
    paymentMethodId: json['paymentMethodId'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    transitionHistory: (json['transitionHistory'] as List<dynamic>?)
        ?.map((t) => SubscriptionTransition.values.firstWhere((s) => s.name == t))
        .toList() ?? [],
    autoRenew: json['autoRenew'] as bool? ?? true,
    lastPaymentDate: json['lastPaymentDate'] != null ? DateTime.parse(json['lastPaymentDate'] as String) : null,
    failedPaymentAttempts: json['failedPaymentAttempts'] as int?,
  );
}

class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? clientSecret;
  final String? errorMessage;
  final PaymentStatus status;
  final Map<String, dynamic>? metadata;

  const PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.clientSecret,
    this.errorMessage,
    required this.status,
    this.metadata,
  });
}

class RefundResult {
  final bool success;
  final String? refundId;
  final int? amountRefunded;
  final String? errorMessage;
  final String? status;

  const RefundResult({
    required this.success,
    this.refundId,
    this.amountRefunded,
    this.errorMessage,
    this.status,
  });
}

class EnhancedSubscriptionService {
  EnhancedSubscriptionService._();
  static final EnhancedSubscriptionService _instance = EnhancedSubscriptionService._();
  factory EnhancedSubscriptionService() => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _subscriptionKey = 'enhanced_subscription_v3';
  static const _userIdKey = 'user_id';
  static const _paymentHistoryKey = 'payment_history';

  // Stripe configuration - should be environment variables
  static const String _stripeSecretKey = 'sk_test_...'; // Replace with actual key
  static const String _stripeWebhookSecret = 'whsec_...'; // Replace with actual secret
  static const String _baseUrl = 'https://api.stripe.com/v1';

  final SecurityService _security = SecurityService();
  final AdvancedSecurityLoggingService _logging = AdvancedSecurityLoggingService();

  final Map<String, String> _stripePrices = {
    'premium_monthly': 'price_1PremiumMonthly',
    'premium_yearly': 'price_1PremiumYearly',
    'lifetime': 'price_1Lifetime',
  };

  /// Initialize the enhanced subscription service
  Future<void> initialize() async {
    try {
      await _validateExistingSubscriptions();
      AppLogger.info('Enhanced Subscription Service initialized');
    } catch (e, st) {
      AppLogger.error('Failed to initialize enhanced subscription service', e, st);
    }
  }

  /// Create or upgrade subscription with instant activation
  Future<PaymentResult> createSubscription({
    required String userId,
    required SubscriptionTierV3 tier,
    required BillingCycle billingCycle,
    String? paymentMethodId,
    String? stripeCustomerId,
    bool trialPeriod = false,
  }) async {
    try {
      // Validate input
      userId = _security.sanitizeInput(userId);
      
      // Check existing subscription
      final existingSub = await getCurrentSubscription();
      
      // Determine transition type
      final transition = _determineTransition(existingSub?.tier, tier);
      
      // Create or update Stripe customer
      final customerId = stripeCustomerId ?? await _createStripeCustomer(userId);
      
      // Process payment based on tier
      PaymentResult paymentResult;
      if (tier == SubscriptionTierV3.free) {
        paymentResult = PaymentResult(
          success: true,
          status: PaymentStatus.succeeded,
        );
      } else {
        paymentResult = await _processPayment(
          customerId,
          tier,
          billingCycle,
          paymentMethodId,
          trialPeriod,
        );
      }
      
      if (!paymentResult.success) {
        await _logging.logBusinessEvent(
          userId: userId,
          event: 'subscription_payment_failed',
          businessData: {
            'tier': tier.id,
            'billingCycle': billingCycle.name,
            'error': paymentResult.errorMessage,
          },
          success: false,
        );
        return paymentResult;
      }
      
      // Create subscription
      final subscription = await _createEnhancedSubscription(
        userId,
        tier,
        billingCycle,
        customerId,
        paymentResult.paymentIntentId,
        transition,
        existingSub,
      );
      
      // Save subscription
      await _saveSubscription(subscription);
      
      // Log successful creation
      await _logging.logBusinessEvent(
        userId: userId,
        event: 'subscription_created',
        businessData: {
          'subscriptionId': subscription.id,
          'tier': tier.id,
          'billingCycle': billingCycle.name,
          'transition': transition.name,
          'amount': tier.price,
        },
      );
      
      AppLogger.info('Subscription created for user: $userId, tier: ${tier.id}');
      return paymentResult;
    } catch (e, st) {
      await _logging.logBusinessEvent(
        userId: userId,
        event: 'subscription_creation_failed',
        businessData: {
          'tier': tier.id,
          'error': e.toString(),
        },
        success: false,
      );
      AppLogger.error('Failed to create subscription', e, st);
      rethrow;
    }
  }

  /// Instant upgrade from free to premium
  Future<PaymentResult> instantUpgrade({
    required String userId,
    required SubscriptionTierV3 targetTier,
    required BillingCycle billingCycle,
    String? paymentMethodId,
  }) async {
    try {
      final currentSub = await getCurrentSubscription();
      
      if (currentSub == null) {
        return await createSubscription(
          userId: userId,
          tier: targetTier,
          billingCycle: billingCycle,
          paymentMethodId: paymentMethodId,
        );
      }
      
      if (currentSub.tier == targetTier) {
        return PaymentResult(
          success: false,
          status: PaymentStatus.failed,
          errorMessage: 'Already subscribed to this tier',
        );
      }
      
      // Process payment for upgrade
      final customerId = currentSub.stripeCustomerId ?? await _createStripeCustomer(userId);
      
      final paymentResult = await _processPayment(
        customerId,
        targetTier,
        billingCycle,
        paymentMethodId,
        false, // No trial for upgrades
      );
      
      if (!paymentResult.success) {
        return paymentResult;
      }
      
      // Upgrade subscription
      final upgradedSub = currentSub.copyWith(
        tier: targetTier,
        billingCycle: billingCycle,
        status: PaymentStatus.succeeded,
        updatedAt: DateTime.now(),
        transitionHistory: [
          ...currentSub.transitionHistory,
          SubscriptionTransition.upgrade,
        ],
        lastPaymentDate: DateTime.now(),
        failedPaymentAttempts: 0,
      );
      
      await _saveSubscription(upgradedSub);
      
      await _logging.logBusinessEvent(
        userId: userId,
        event: 'subscription_upgraded',
        businessData: {
          'fromTier': currentSub.tier.id,
          'toTier': targetTier.id,
          'amount': targetTier.price,
        },
      );
      
      AppLogger.info('Instant upgrade completed for user: $userId');
      return paymentResult;
    } catch (e, st) {
      AppLogger.error('Failed to instant upgrade', e, st);
      rethrow;
    }
  }

  /// Cancel subscription with proration
  Future<bool> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
    String? reason,
  }) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null || subscription.id != subscriptionId) {
        throw ArgumentError('Subscription not found');
      }
      
      // Cancel in Stripe
      if (subscription.stripeSubscriptionId != null) {
        await _cancelStripeSubscription(subscription.stripeSubscriptionId!, immediate);
      }
      
      // Update local subscription
      final canceledSub = subscription.copyWith(
        status: immediate ? PaymentStatus.canceled : PaymentStatus.succeeded,
        canceledAt: DateTime.now(),
        autoRenew: false,
        updatedAt: DateTime.now(),
        transitionHistory: [
          ...subscription.transitionHistory,
          SubscriptionTransition.cancellation,
        ],
      );
      
      await _saveSubscription(canceledSub);
      
      await _logging.logBusinessEvent(
        userId: subscription.userId,
        event: 'subscription_canceled',
        businessData: {
          'subscriptionId': subscriptionId,
          'immediate': immediate,
          'reason': reason,
        },
      );
      
      AppLogger.info('Subscription canceled: $subscriptionId');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to cancel subscription', e, st);
      return false;
    }
  }

  /// Process refund with proration calculation
  Future<RefundResult> processRefund({
    required String subscriptionId,
    int? amount,
    String? reason,
  }) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null || subscription.id != subscriptionId) {
        throw ArgumentError('Subscription not found');
      }
      
      if (subscription.stripeSubscriptionId == null) {
        return const RefundResult(
          success: false,
          errorMessage: 'No associated Stripe subscription',
        );
      }
      
      // Calculate refund amount if not specified
      final refundAmount = amount ?? _calculateProratedRefund(subscription);
      
      // Process refund in Stripe
      final refundResult = await _createStripeRefund(
        subscription.stripeSubscriptionId!,
        refundAmount,
        reason,
      );
      
      if (refundResult.success) {
        // Update subscription status
        final updatedSub = subscription.copyWith(
          status: refundResult.status == 'succeeded' ? PaymentStatus.refunded : PaymentStatus.partially_refunded,
          updatedAt: DateTime.now(),
          metadata: {
            ...subscription.metadata,
            'refundId': refundResult.refundId,
            'refundAmount': refundAmount,
            'refundReason': reason,
          },
        );
        
        await _saveSubscription(updatedSub);
        
        await _logging.logBusinessEvent(
          userId: subscription.userId,
          event: 'refund_processed',
          businessData: {
            'subscriptionId': subscriptionId,
            'refundAmount': refundAmount,
            'refundId': refundResult.refundId,
            'reason': reason,
          },
        );
      }
      
      return refundResult;
    } catch (e, st) {
      AppLogger.error('Failed to process refund', e, st);
      return const RefundResult(
        success: false,
        errorMessage: 'Refund processing failed',
      );
    }
  }

  /// Handle enhanced Stripe webhooks
  Future<void> handleStripeWebhook(String payload, String signature) async {
    try {
      // Verify webhook signature
      if (!_verifyWebhookSignature(payload, signature)) {
        throw SecurityViolationException('Invalid webhook signature', SecurityViolationType.suspiciousActivity);
      }
      
      final event = jsonDecode(payload) as Map<String, dynamic>;
      final eventType = event['type'] as String;
      
      switch (eventType) {
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
        case 'invoice.created':
          await _handleInvoiceCreated(event);
          break;
        case 'payment_intent.succeeded':
          await _handlePaymentIntentSucceeded(event);
          break;
        case 'payment_intent.payment_failed':
          await _handlePaymentIntentFailed(event);
          break;
        default:
          AppLogger.info('Unhandled webhook event: $eventType');
      }
      
      await _logging.logBusinessEvent(
        userId: 'system',
        event: 'stripe_webhook_processed',
        businessData: {
          'eventType': eventType,
          'eventId': event['id'],
        },
      );
    } catch (e, st) {
      AppLogger.error('Failed to handle Stripe webhook', e, st);
      rethrow;
    }
  }

  /// Get current subscription with enhanced validation
  Future<EnhancedSubscription?> getCurrentSubscription() async {
    try {
      final subscriptionJson = await _storage.read(key: _subscriptionKey);
      if (subscriptionJson != null) {
        final subscription = EnhancedSubscription.fromJson(jsonDecode(subscriptionJson) as Map<String, dynamic>);
        
        // Validate subscription status
        await _validateSubscriptionStatus(subscription);
        
        return subscription;
      }
    } catch (e, st) {
      AppLogger.error('Failed to load subscription', e, st);
    }
    return null;
  }

  /// Check if user has access to specific features
  Future<bool> hasFeatureAccess({
    required String userId,
    required String feature,
    int? documentCount,
    int? heirCount,
  }) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;
      
      if (!subscription.isActive) return false;
      
      // Check feature access based on tier
      switch (subscription.tier) {
        case SubscriptionTierV3.free:
          return _checkFreeTierAccess(feature, documentCount, heirCount);
        case SubscriptionTierV3.premium:
          return _checkPremiumTierAccess(feature, documentCount, heirCount);
        case SubscriptionTierV3.lifetime:
          return true; // Lifetime has all features
      }
    } catch (e, st) {
      AppLogger.error('Failed to check feature access', e, st);
      return false;
    }
  }

  /// Get subscription analytics
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return {};
      
      return {
        'currentTier': subscription.tier.id,
        'billingCycle': subscription.billingCycle.name,
        'status': subscription.status.name,
        'isActive': subscription.isActive,
        'isTrialActive': subscription.isTrialActive,
        'daysUntilRenewal': subscription.currentPeriodEnd?.difference(DateTime.now()).inDays,
        'autoRenew': subscription.autoRenew,
        'lastPaymentDate': subscription.lastPaymentDate?.toIso8601String(),
        'failedPaymentAttempts': subscription.failedPaymentAttempts,
        'transitionHistory': subscription.transitionHistory.map((t) => t.name).toList(),
        'features': {
          'maxDocuments': subscription.tier.maxDocuments,
          'maxHeirs': subscription.tier.maxHeirs,
          'hasDeadMansSwitch': subscription.tier != SubscriptionTierV3.free,
          'hasConditionalInheritance': subscription.tier != SubscriptionTierV3.free,
          'hasMultiChannelCheckIn': subscription.tier != SubscriptionTierV3.free,
        },
      };
    } catch (e, st) {
      AppLogger.error('Failed to get subscription analytics', e, st);
      return {};
    }
  }

  /// Private methods

  SubscriptionTransition _determineTransition(SubscriptionTierV3? fromTier, SubscriptionTierV3 toTier) {
    if (fromTier == null) return SubscriptionTransition.free_to_premium;
    
    if (fromTier == SubscriptionTierV3.free && toTier == SubscriptionTierV3.premium) {
      return SubscriptionTransition.free_to_premium;
    } else if (fromTier == SubscriptionTierV3.premium && toTier == SubscriptionTierV3.lifetime) {
      return SubscriptionTransition.premium_to_lifetime;
    } else if (fromTier == SubscriptionTierV3.lifetime && toTier == SubscriptionTierV3.premium) {
      return SubscriptionTransition.lifetime_to_premium;
    } else if (fromTier.index < toTier.index) {
      return SubscriptionTransition.upgrade;
    } else if (fromTier.index > toTier.index) {
      return SubscriptionTransition.downgrade;
    } else {
      return SubscriptionTransition.any_to_free;
    }
  }

  Future<PaymentResult> _processPayment(
    String customerId,
    SubscriptionTierV3 tier,
    BillingCycle billingCycle,
    String? paymentMethodId,
    bool trialPeriod,
  ) async {
    try {
      final priceId = _getPriceIdForTier(tier, billingCycle);
      
      final body = <String, String>{
        'customer': customerId,
        'payment_method': paymentMethodId ?? '',
        'confirm': 'true',
      };
      
      if (trialPeriod) {
        body['trial_period_days'] = '14';
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('Payment failed: ${response.body}');
      }
      
      final paymentIntent = jsonDecode(response.body) as Map<String, dynamic>;
      
      return PaymentResult(
        success: paymentIntent['status'] == 'succeeded',
        paymentIntentId: paymentIntent['id'] as String,
        clientSecret: paymentIntent['client_secret'] as String?,
        status: _mapStripeStatus(paymentIntent['status'] as String),
      );
    } catch (e, st) {
      AppLogger.error('Payment processing failed', e, st);
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<EnhancedSubscription> _createEnhancedSubscription(
    String userId,
    SubscriptionTierV3 tier,
    BillingCycle billingCycle,
    String customerId,
    String? paymentIntentId,
    SubscriptionTransition transition,
    EnhancedSubscription? existingSub,
  ) async {
    final now = DateTime.now();
    DateTime? periodStart, periodEnd;
    
    if (tier == SubscriptionTierV3.lifetime) {
      periodStart = now;
      periodEnd = null; // Lifetime subscriptions don't expire
    } else if (tier == SubscriptionTierV3.free) {
      periodStart = now;
      periodEnd = null; // Free subscriptions don't expire
    } else {
      periodStart = now;
      periodEnd = _calculatePeriodEnd(billingCycle, now);
    }
    
    return EnhancedSubscription(
      id: _generateId(),
      userId: userId,
      tier: tier,
      billingCycle: billingCycle,
      status: paymentIntentId != null ? PaymentStatus.succeeded : PaymentStatus.succeeded,
      currentPeriodStart: periodStart,
      currentPeriodEnd: periodEnd,
      stripeCustomerId: customerId,
      paymentMethodId: paymentIntentId,
      createdAt: existingSub?.createdAt ?? now,
      updatedAt: now,
      transitionHistory: existingSub != null 
          ? [...existingSub.transitionHistory, transition]
          : [transition],
      lastPaymentDate: paymentIntentId != null ? now : null,
      failedPaymentAttempts: 0,
    );
  }

  DateTime _calculatePeriodEnd(BillingCycle cycle, DateTime startDate) {
    switch (cycle) {
      case BillingCycle.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BillingCycle.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      case BillingCycle.lifetime:
        return DateTime(2100, 12, 31); // Far future date for lifetime
    }
  }

  String _getPriceIdForTier(SubscriptionTierV3 tier, BillingCycle cycle) {
    switch (tier) {
      case SubscriptionTierV3.premium:
        return cycle == BillingCycle.yearly 
            ? _stripePrices['premium_yearly']!
            : _stripePrices['premium_monthly']!;
      case SubscriptionTierV3.lifetime:
        return _stripePrices['lifetime']!;
      default:
        throw ArgumentError('Invalid tier for paid subscription: ${tier.id}');
    }
  }

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
      ).timeout(const Duration(seconds: 30));
      
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

  Future<void> _cancelStripeSubscription(String subscriptionId, bool immediate) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
        },
        body: immediate ? {} : {'cancel_at_period_end': 'true'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel Stripe subscription: ${response.body}');
      }
    } catch (e, st) {
      AppLogger.error('Failed to cancel Stripe subscription', e, st);
      rethrow;
    }
  }

  Future<RefundResult> _createStripeRefund(String subscriptionId, int amount, String? reason) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_intent': subscriptionId,
          'amount': amount.toString(),
          'reason': reason ?? 'requested_by_customer',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to create refund: ${response.body}');
      }
      
      final refund = jsonDecode(response.body) as Map<String, dynamic>;
      
      return RefundResult(
        success: refund['status'] == 'succeeded',
        refundId: refund['id'] as String,
        amountRefunded: refund['amount'] as int,
        status: refund['status'] as String,
      );
    } catch (e, st) {
      AppLogger.error('Failed to create refund', e, st);
      return const RefundResult(
        success: false,
        errorMessage: 'Refund creation failed',
      );
    }
  }

  int _calculateProratedRefund(EnhancedSubscription subscription) {
    if (subscription.currentPeriodEnd == null) return 0;
    
    final totalPeriod = subscription.currentPeriodEnd!.difference(subscription.currentPeriodStart!);
    final remainingPeriod = subscription.currentPeriodEnd!.difference(DateTime.now());
    
    if (remainingPeriod.isNegative) return 0;
    
    final refundRatio = remainingPeriod.inDays / totalPeriod.inDays;
    return (subscription.tier.price * refundRatio).round();
  }

  bool _verifyWebhookSignature(String payload, String signature) {
    // In production, implement proper signature verification
    return signature.isNotEmpty && payload.isNotEmpty;
  }

  PaymentStatus _mapStripeStatus(String stripeStatus) {
    switch (stripeStatus) {
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'processing':
        return PaymentStatus.processing;
      case 'requires_payment_method':
        return PaymentStatus.pending;
      case 'requires_confirmation':
        return PaymentStatus.pending;
      case 'requires_action':
        return PaymentStatus.pending;
      case 'canceled':
        return PaymentStatus.canceled;
      default:
        return PaymentStatus.failed;
    }
  }

  Future<void> _handlePaymentSucceeded(Map<String, dynamic> event) async {
    // Handle successful payment
    AppLogger.info('Payment succeeded: ${event['id']}');
  }

  Future<void> _handlePaymentFailed(Map<String, dynamic> event) async {
    // Handle failed payment
    AppLogger.warning('Payment failed: ${event['id']}');
  }

  Future<void> _handleSubscriptionDeleted(Map<String, dynamic> event) async {
    // Handle subscription deletion
    AppLogger.info('Subscription deleted: ${event['id']}');
  }

  Future<void> _handleSubscriptionUpdated(Map<String, dynamic> event) async {
    // Handle subscription update
    AppLogger.info('Subscription updated: ${event['id']}');
  }

  Future<void> _handleInvoiceCreated(Map<String, dynamic> event) async {
    // Handle invoice creation
    AppLogger.info('Invoice created: ${event['id']}');
  }

  Future<void> _handlePaymentIntentSucceeded(Map<String, dynamic> event) async {
    // Handle payment intent success
    AppLogger.info('Payment intent succeeded: ${event['id']}');
  }

  Future<void> _handlePaymentIntentFailed(Map<String, dynamic> event) async {
    // Handle payment intent failure
    AppLogger.warning('Payment intent failed: ${event['id']}');
  }

  Future<void> _validateSubscriptionStatus(EnhancedSubscription subscription) async {
    // Check if subscription needs validation with Stripe
    if (subscription.stripeSubscriptionId != null && subscription.isActive) {
      // In production, validate with Stripe API
      if (subscription.isExpired) {
        final updatedSub = subscription.copyWith(
          status: PaymentStatus.failed,
          updatedAt: DateTime.now(),
        );
        await _saveSubscription(updatedSub);
      }
    }
  }

  Future<void> _validateExistingSubscriptions() async {
    // Validate and migrate existing subscriptions if needed
    final existing = await getCurrentSubscription();
    if (existing != null) {
      await _validateSubscriptionStatus(existing);
    }
  }

  bool _checkFreeTierAccess(String feature, int? documentCount, int? heirCount) {
    switch (feature) {
      case 'documents':
        return documentCount == null || documentCount <= 10;
      case 'heirs':
        return heirCount == null || heirCount <= 1;
      case 'dead_mans_switch':
        return false;
      case 'conditional_inheritance':
        return false;
      case 'multi_channel_checkin':
        return false;
      default:
        return false;
    }
  }

  bool _checkPremiumTierAccess(String feature, int? documentCount, int? heirCount) {
    switch (feature) {
      case 'documents':
        return documentCount == null || documentCount <= 100;
      case 'heirs':
        return heirCount == null || heirCount <= 5;
      case 'dead_mans_switch':
        return true;
      case 'conditional_inheritance':
        return true;
      case 'multi_channel_checkin':
        return true;
      default:
        return true;
    }
  }

  Future<void> _saveSubscription(EnhancedSubscription subscription) async {
    try {
      await _storage.write(
        key: _subscriptionKey,
        value: jsonEncode(subscription.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('Failed to save subscription', e, st);
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(10000).toString();
  }
}
