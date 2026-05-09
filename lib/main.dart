// Digital Vault Heritage v3.0 - Main Application Entry Point
// Copyright © 2026 Aeternal Heritage. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core imports
import 'core/logger.dart';
import 'core/services/supabase_service.dart';
import 'core/services/stripe_service.dart';
import 'core/services/dead_mans_switch_enhanced_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('BG Message ricevuto: ${message.messageId}');
}

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize localization service
  // await LocalizationService.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.blueGrey,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.info('Foreground notification: ${message.messageId}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.info('Opened app from notification: ${message.messageId}');
    });
  } catch (e, st) {
    AppLogger.warning('Firebase not initialized: $e');
    AppLogger.error('Firebase stacktrace', e, st);
  }

  // Initialize Supabase
  try {
    await SupabaseService.instance.initialize();
    AppLogger.info('Supabase initialized successfully');
  } catch (e, st) {
    AppLogger.error('Failed to initialize Supabase', e, st);
  }

  // Initialize Stripe
  try {
    await StripeService.instance.initialize();
    AppLogger.info('Stripe initialized successfully');
  } catch (e, st) {
    AppLogger.error('Failed to initialize Stripe', e, st);
  }

  // Initialize Enhanced Dead Man's Switch
  try {
    await DeadMansSwitchEnhancedService.instance.initialize();
    AppLogger.info('Enhanced Dead Man\'s Switch service initialized');
  } catch (e, st) {
    AppLogger.error('Failed to initialize DMS service', e, st);
  }

  // Enable screenshot protection
  // await ScreenshotProtection.enable();

  // Run the app
  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          // Initialize localization stream listener
          // ref.listen(localizationServiceProvider, (previous, next) {
          //   // Handle locale changes if needed
          // });

          return AeternaApp();
        },
      ),
    ),
  );
}

class AeternaApp extends ConsumerStatefulWidget {
  const AeternaApp({super.key});

  @override
  ConsumerState<AeternaApp> createState() => _AeternaAppState();
}

class _AeternaAppState extends ConsumerState<AeternaApp> {
  // final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  void initState() {
    super.initState();
    // _lifecycleManager.init();
    
    // Initialize migration service
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Note: Migration service would be implemented if needed
      AppLogger.info('App initialization completed');
    });
  }

  @override
  void dispose() {
    // _lifecycleManager.dispose();
    DeadMansSwitchEnhancedService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final router = ref.watch(appRouterProvider);
    // final localizationService = LocalizationService.instance;
    
    return MaterialApp.router(
      title: 'Digital Vault Heritage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // routerConfig: router,
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
      ],
      // locale: localizationService.currentLocale,
      
      // Builder for global styling and footer
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Ensure text scale factor is reasonable
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2)),
          ),
          child: Scaffold(
            body: child!,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Language selector - Temporarily commented out
                      // const LanguageSelector(),
                      const SizedBox(width: 20),
                      // Copyright notice
                      Text(
                        '© 2026 Aeternal Heritage',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Legal policy link
                      TextButton(
                        onPressed: () {
                          // Open legal policy
                          // TODO: Implement legal policy navigation
                        },
                        child: Text(
                          'Legal Policy',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
