// Stripe Payment Service for Digital Vault Heritage v3.0
// Copyright © 2026 Aeternal Heritage. All rights reserved.

import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StripeService {
  static StripeService? _instance;
  static StripeService get instance => _instance ??= StripeService._();

  StripeService._();

  final Uuid _uuid = const Uuid();
  late final String _stripeSecretKey;
  late final String _stripePublishableKey;

  // Initialize Stripe with environment variables
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      
      _stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
      _stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      
      // Initialize Stripe SDK
      Stripe.publishableKey = _stripePublishableKey;
      
      print('Stripe initialized successfully');
    } catch (e) {
      print('Failed to initialize Stripe: $e');
      rethrow;
    }
  }

  // Create checkout session for different plans
  Future<Map<String, dynamic>> createCheckoutSession(
    String userId,
    String planType,
    String successUrl,
    String cancelUrl,
  ) async {
    try {
      final priceId = _getPriceIdForPlan(planType);
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types': 'card',
          'mode': 'payment',
          'line_items': jsonEncode([
            {
              'price': priceId,
              'quantity': 1,
            }
          ]),
          'success_url': '$successUrl?session_id={CHECKOUT_SESSION_ID}',
          'cancel_url': cancelUrl,
          'customer_email': await _getUserEmail(userId),
          'metadata': {
            'user_id': userId,
            'plan_type': planType,
            'session_id': _uuid.v4(),
          },
          'allow_promotion_codes': 'true',
        },
      );

      if (response.statusCode == 200) {
        final sessionData = jsonDecode(response.body);
        return {
          'success': true,
          'sessionId': sessionData['id'],
          'url': sessionData['url'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create checkout session',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Create checkout session error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create subscription checkout session
  Future<Map<String, dynamic>> createSubscriptionCheckoutSession(
    String userId,
    String planType,
    String successUrl,
    String cancelUrl,
  ) async {
    try {
      final priceId = _getPriceIdForPlan(planType);
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types': 'card',
          'mode': 'subscription',
          'line_items': jsonEncode([
            {
              'price': priceId,
              'quantity': 1,
            }
          ]),
          'success_url': '$successUrl?session_id={CHECKOUT_SESSION_ID}',
          'cancel_url': cancelUrl,
          'customer_email': await _getUserEmail(userId),
          'metadata': {
            'user_id': userId,
            'plan_type': planType,
            'session_id': _uuid.v4(),
          },
          'allow_promotion_codes': 'true',
          'subscription_data[metadata][user_id]': userId,
          'subscription_data[metadata][plan_type]': planType,
        },
      );

      if (response.statusCode == 200) {
        final sessionData = jsonDecode(response.body);
        return {
          'success': true,
          'sessionId': sessionData['id'],
          'url': sessionData['url'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create subscription session',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Create subscription checkout error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Handle Stripe webhook for checkout.session.completed
  Future<Map<String, dynamic>> handleWebhook(String payload, String signature) async {
    try {
      // Verify webhook signature
      final event = _constructWebhookEvent(payload, signature);
      
      if (event == null) {
        return {
          'success': false,
          'error': 'Invalid webhook signature',
        };
      }

      // Handle checkout.session.completed event
      if (event.type == 'checkout.session.completed') {
        final session = event.data.object;
        await _processCompletedCheckout(session);
      }

      // Handle invoice.payment_succeeded event (for subscriptions)
      if (event.type == 'invoice.payment_succeeded') {
        final invoice = event.data.object;
        await _processSuccessfulPayment(invoice);
      }

      // Handle customer.subscription.deleted event
      if (event.type == 'customer.subscription.deleted') {
        final subscription = event.data.object;
        await _processCancelledSubscription(subscription);
      }

      return {
        'success': true,
        'event': event.type,
        'processed': true,
      };
    } catch (e) {
      print('Webhook handling error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Process completed checkout
  Future<void> _processCompletedCheckout(Map<String, dynamic> session) async {
    try {
      final userId = session['metadata']['user_id'];
      final planType = session['metadata']['plan_type'];
      final paymentStatus = session['payment_status'];
      
      if (paymentStatus == 'paid') {
        // Update user subscription in Supabase
        await _updateUserSubscription(userId, planType, session);
        
        // Send confirmation email
        await _sendPaymentConfirmationEmail(userId, planType, session);
        
        print('Payment processed successfully for user: $userId, plan: $planType');
      }
    } catch (e) {
      print('Process completed checkout error: $e');
    }
  }

  // Process successful payment (for subscriptions)
  Future<void> _processSuccessfulPayment(Map<String, dynamic> invoice) async {
    try {
      final subscription = invoice['subscription'];
      final metadata = subscription['metadata'];
      
      if (metadata != null) {
        final userId = metadata['user_id'];
        final planType = metadata['plan_type'];
        
        // Update subscription status
        await _updateUserSubscription(userId, planType, invoice);
        
        print('Subscription payment processed for user: $userId');
      }
    } catch (e) {
      print('Process successful payment error: $e');
    }
  }

  // Process cancelled subscription
  Future<void> _processCancelledSubscription(Map<String, dynamic> subscription) async {
    try {
      final metadata = subscription['metadata'];
      
      if (metadata != null) {
        final userId = metadata['user_id'];
        
        // Update user to free plan
        await _updateUserSubscription(userId, 'free', subscription);
        
        print('Subscription cancelled for user: $userId');
      }
    } catch (e) {
      print('Process cancelled subscription error: $e');
    }
  }

  // Update user subscription in Supabase
  Future<void> _updateUserSubscription(
    String userId,
    String planType,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('user_subscriptions')
          .upsert({
            'user_id': userId,
            'plan_type': planType,
            'stripe_customer_id': paymentData['customer'] ?? '',
            'stripe_subscription_id': paymentData['subscription'] ?? '',
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
            'payment_data': paymentData,
          });
      
      print('User subscription updated: $userId -> $planType');
    } catch (e) {
      print('Update user subscription error: $e');
    }
  }

  // Get user email from Supabase
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

  // Send payment confirmation email
  Future<void> _sendPaymentConfirmationEmail(
    String userId,
    String planType,
    Map<String, dynamic> session,
  ) async {
    try {
      // This would integrate with your email service
      // For now, we'll log the action
      print('Payment confirmation email sent to user: $userId');
      print('Plan: $planType');
      print('Session: ${session['id']}');
      
      // TODO: Implement actual email sending
      // await EmailService.sendPaymentConfirmation(userId, planType, session);
    } catch (e) {
      print('Send payment confirmation email error: $e');
    }
  }

  // Get price ID for plan
  String _getPriceIdForPlan(String planType) {
    switch (planType.toLowerCase()) {
      case 'premium_monthly':
        return dotenv.env['STRIPE_PRICE_PREMIUM_MONTHLY'] ?? 'price_premium_monthly';
      case 'premium_yearly':
        return dotenv.env['STRIPE_PRICE_PREMIUM_YEARLY'] ?? 'price_premium_yearly';
      case 'lifetime':
        return dotenv.env['STRIPE_PRICE_LIFETIME'] ?? 'price_lifetime';
      default:
        throw Exception('Invalid plan type: $planType');
    }
  }

  // Construct webhook event (simplified version)
  dynamic _constructWebhookEvent(String payload, String signature) {
    try {
      // In production, you should use Stripe's webhook signing library
      // This is a simplified version for demonstration
      final event = jsonDecode(payload);
      return event;
    } catch (e) {
      print('Webhook construction error: $e');
      return null;
    }
  }

  // Get subscription plans
  List<Map<String, dynamic>> getSubscriptionPlans() {
    return [
      {
        'id': 'free',
        'name': 'Free Plan',
        'price': 0,
        'currency': 'USD',
        'interval': 'month',
        'features': [
          '10 documents',
          '1 heir',
          'Basic security',
        ],
        'stripePriceId': null,
      },
      {
        'id': 'premium_monthly',
        'name': 'Premium Plan (Monthly)',
        'price': 999, // $9.99 in cents
        'currency': 'USD',
        'interval': 'month',
        'features': [
          '100 documents',
          '5 heirs',
          'Advanced security',
          'Dead Man\'s Switch',
          'Priority support',
        ],
        'stripePriceId': dotenv.env['STRIPE_PRICE_PREMIUM_MONTHLY'],
      },
      {
        'id': 'premium_yearly',
        'name': 'Premium Plan (Yearly)',
        'price': 9999, // $99.99 in cents
        'currency': 'USD',
        'interval': 'year',
        'features': [
          '100 documents',
          '5 heirs',
          'Advanced security',
          'Dead Man\'s Switch',
          'Priority support',
          '2 months free',
        ],
        'stripePriceId': dotenv.env['STRIPE_PRICE_PREMIUM_YEARLY'],
      },
      {
        'id': 'lifetime',
        'name': 'Lifetime Plan',
        'price': 29999, // $299.99 in cents
        'currency': 'USD',
        'interval': 'once',
        'features': [
          'Unlimited documents',
          'Unlimited heirs',
          'All features',
          'Lifetime support',
        ],
        'stripePriceId': dotenv.env['STRIPE_PRICE_LIFETIME'],
      },
    ];
  }

  // Get publishable key for frontend
  String get publishableKey => _stripePublishableKey;

  // Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Check active subscription error: $e');
      return false;
    }
  }

  // Cancel user subscription
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get user's subscription
      final subscription = await supabase
          .from('user_subscriptions')
          .select('stripe_subscription_id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      
      if (subscription == null) {
        return {
          'success': false,
          'error': 'No active subscription found',
        };
      }

      // Cancel subscription in Stripe
      final stripeSubscriptionId = subscription['stripe_subscription_id'];
      if (stripeSubscriptionId != null && stripeSubscriptionId.isNotEmpty) {
        final response = await http.post(
          Uri.parse('https://api.stripe.com/v1/subscriptions/$stripeSubscriptionId/cancel'),
          headers: {
            'Authorization': 'Bearer $_stripeSecretKey',
          },
        );

        if (response.statusCode != 200) {
          return {
            'success': false,
            'error': 'Failed to cancel subscription in Stripe',
          };
        }
      }

      // Update in database
      await supabase
          .from('user_subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      return {
        'success': true,
        'message': 'Subscription cancelled successfully',
      };
    } catch (e) {
      print('Cancel subscription error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
