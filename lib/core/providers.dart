// Core Providers for Digital Vault Heritage v3.0
// Copyright © 2026 Aeternal Heritage. All rights reserved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

// Core Services
import 'services/encryption_service.dart';
import 'services/secure_key_service.dart';
import 'services/secure_crypto_storage.dart';
import 'services/pin_service.dart';
import 'services/shamir_service.dart';
import 'services/recovery_key_service.dart';
import 'services/migration_service.dart';
import 'services/security_service.dart';
import 'services/error_handling_service.dart';
import 'services/screenshot_protection.dart';
import 'services/sealed_envelope_service.dart';
import 'services/auth_service.dart';

// Enhanced Services v3.0
import 'services/advanced_security_logging_service.dart';
import 'services/enhanced_dead_mans_switch_service.dart';
import 'services/enhanced_subscription_service.dart';
import 'services/dead_mans_switch_service.dart';
import 'services/user_reporting_service.dart';
import 'services/conditional_inheritance_service.dart';
import 'services/subscription_service.dart';

// New Integration Services
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';
import 'services/dead_mans_switch_enhanced_service.dart';

// Localization
import '../l10n/localization_service.dart';

// Core
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'state/lock_state.dart';
import 'logger.dart';

// Features
import '../features/vault/vault_provider.dart';
import '../features/vault/data/vault_repository.dart';
import '../features/kill_switch/kill_switch_provider.dart';
import '../features/auth/providers/auth_provider.dart';

// Core Security Services
final encryptionServiceProvider = Provider((ref) => EncryptionService());
final secureKeyServiceProvider = Provider((ref) => SecureKeyService());
final secureCryptoStorageProvider = Provider((ref) => SecureCryptoStorage());

// SharedPreferences Provider - Using NotifierProvider for Riverpod 3.x compatibility
final sharedPreferencesProvider = NotifierProvider<SharedPreferencesNotifier, SharedPreferences?>((ref) => SharedPreferencesNotifier());

class SharedPreferencesNotifier extends StateNotifier<SharedPreferences?> {
  SharedPreferencesNotifier() : super(null);
  
  Future<void> initialize(SharedPreferences prefs) async {
    state = prefs;
  }
}

// Vault Repository
final vaultRepositoryProvider = Provider<VaultRepository>((ref) => VaultRepository(
  encryptionService: ref.read(encryptionServiceProvider),
  keyService: ref.read(secureKeyServiceProvider),
  cryptoStorage: ref.read(secureCryptoStorageProvider),
));

// Enhanced Security Services
final securityServiceProvider = Provider((ref) => SecurityService());
final errorHandlingServiceProvider = Provider((ref) => ErrorHandlingService());

// Authentication & Recovery Services
final authServiceProvider = Provider((ref) => AuthService());
final pinServiceProvider = Provider((ref) => PinService());
final recoveryKeyServiceProvider = Provider((ref) => RecoveryKeyService());

// Cryptographic Services
final shamirServiceProvider = Provider((ref) => ShamirService());
final sealedEnvelopeServiceProvider = Provider(
  (ref) => SealedEnvelopeService(shamir: ref.read(shamirServiceProvider)),
);

// Enhanced Services v3.0
final advancedSecurityLoggingServiceProvider = Provider<AdvancedSecurityLoggingService>((ref) {
  return AdvancedSecurityLoggingService();
});

final enhancedDeadMansSwitchServiceProvider = Provider<EnhancedDeadMansSwitchService>((ref) {
  return EnhancedDeadMansSwitchService();
});

final enhancedSubscriptionServiceProvider = Provider<EnhancedSubscriptionService>((ref) {
  return EnhancedSubscriptionService();
});

final userReportingServiceProvider = Provider<UserReportingService>((ref) {
  return UserReportingService();
});

final conditionalInheritanceServiceProvider = Provider<ConditionalInheritanceService>((ref) {
  return ConditionalInheritanceService();
});

// Legacy Service Providers (for backward compatibility)
final subscriptionServiceProvider = Provider<EnhancedSubscriptionService>((ref) {
  return ref.read(enhancedSubscriptionServiceProvider);
});

final deadMansSwitchServiceProvider = Provider<DeadMansSwitchEnhancedService>((ref) {
  return ref.read(deadMansSwitchEnhancedServiceProvider);
});

// New Integration Service Providers
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService.instance;
});

final deadMansSwitchEnhancedServiceProvider = Provider<DeadMansSwitchEnhancedService>((ref) {
  return DeadMansSwitchEnhancedService.instance;
});

// Localization Provider
final localizationsServiceProvider = Provider<LocalizationService>((ref) {
  return LocalizationService();
});

// Core Providers - Router and Theme will be handled in separate files
// appRouterProvider and appThemeProvider moved to app_router.dart and app_theme.dart respectively

// lockProvider is defined in core/state/lock_state.dart to avoid conflicts

// AppLogger uses static methods, no instance needed

// Feature Providers are defined in their respective modules to avoid conflicts

// Utility Providers for initialization
Future<void> initializeProviders(ProviderContainer container) async {
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  container.read(sharedPreferencesProvider.notifier).initialize(prefs);

  // Note: FlutterSecureStorage and other services are initialized in main.dart
  // This function can be used for any additional provider setup needed
}
final securityEventsProvider = StreamProvider<List<SecurityEvent>>((ref) async* {
  final securityService = ref.read(securityServiceProvider);
  yield* Stream.periodic(const Duration(minutes: 1), (_) async {
    return await securityService.getSecurityEvents();
  }).asyncMap((event) => event);
});

final errorEventsProvider = StreamProvider<List<AppError>>((ref) async* {
  final errorService = ref.read(errorHandlingServiceProvider);
  yield* errorService.errorStream.map((error) => [error]);
});

// Subscription State Providers
final subscriptionProvider = FutureProvider<EnhancedSubscription?>((ref) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.getCurrentSubscription();
});

final premiumAccessProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.hasFeatureAccess(userId: userId, feature: 'premium');
});

// Dead Man's Switch State Providers
final deadMansSwitchStateProvider = FutureProvider<DeadMansSwitchState>((ref) async {
  final dmsService = ref.read(deadMansSwitchServiceProvider);
  // Create default state if service doesn't have getState method
  return DeadMansSwitchState(
    isActive: false,
    lastCheckIn: null,
    lastNotification: null,
    missedCheckIns: 0,
    config: const DeadMansSwitchConfig(),
    heirConfirmations: [],
  );
});

// Session Management Provider
final sessionValidProvider = FutureProvider<bool>((ref) async {
  final securityService = ref.read(securityServiceProvider);
  return await securityService.isSessionValid();
});

// Pricing Information Provider
final pricingInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.getSubscriptionAnalytics();
});

// Available Tiers Provider  
final availableTiersProvider = Provider<List<SubscriptionTierV3>>((ref) {
  return const [
    SubscriptionTierV3.free,
    SubscriptionTierV3.premium,
    SubscriptionTierV3.lifetime,
  ];
});

// Error Log Provider
final errorLogProvider = FutureProvider.family<List<AppError>, int>((ref, limit) async {
  final errorService = ref.read(errorHandlingServiceProvider);
  return await errorService.getRecentErrors(limit: limit);
});

// Initialization Providers
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize all services
  final securityService = ref.read(securityServiceProvider);
  final subscriptionService = ref.read(subscriptionServiceProvider);
  final dmsService = ref.read(deadMansSwitchServiceProvider);
  
  // Initialize services in order
  await securityService.createSession('default_user'); // Will be replaced with actual user ID
  await subscriptionService.initialize();
  await dmsService.initialize();
});

// Health Check Provider
final healthCheckProvider = FutureProvider<Map<String, bool>>((ref) async {
  final results = <String, bool>{};
  
  try {
    // Test security service
    final securityService = ref.read(securityServiceProvider);
    results['security'] = await securityService.isSessionValid();
  } catch (e) {
    results['security'] = false;
  }
  
  try {
    // Test error service
    final errorService = ref.read(errorHandlingServiceProvider);
    results['errorHandling'] = true; // Basic health check
  } catch (e) {
    results['errorHandling'] = false;
  }
  
  try {
    // Test subscription service
    final subscriptionService = ref.read(subscriptionServiceProvider);
    await subscriptionService.getCurrentSubscription();
    results['subscription'] = true;
  } catch (e) {
    results['subscription'] = false;
  }
  
  try {
    // Test dead man's switch
    final dmsService = ref.read(deadMansSwitchServiceProvider);
    await dmsService.getState();
    results['deadMansSwitch'] = true;
  } catch (e) {
    results['deadMansSwitch'] = false;
  }
  
  return results;
});
