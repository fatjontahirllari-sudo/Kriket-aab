import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './core/app_export.dart';
import './providers/app_providers.dart';
import './services/biometric_service.dart';
import './services/google_auth_service.dart';
import './services/session_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';


// Handles FCM messages received while the app is in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Push Notifications.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (!kIsWeb) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] Token: $token');
    }
  } catch (e) {
    debugPrint('[FCM] Initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Print Google Sign-In diagnostics on every launch (visible in APK logs)
  GoogleAuthService.printDiagnostics();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  GoRouter.optionURLReflectsImperativeAPIs = true;

  // 🚨 CRITICAL: Device orientation lock — skip on web (not supported)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen for password recovery deep link
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        appRouter.go(AppRoutes.resetPassword);
      }

      // Persist session on sign-in / token refresh
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        if (data.session != null) {
          SessionService.instance.persistSession(data.session!);
          // Keep biometric session tokens fresh
          _updateBiometricSessionIfEnabled(data.session!);
        }
      }

      // Clear stored session on sign-out or user deletion
      if (data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.userDeleted) {
        SessionService.instance.clearSession();
        BiometricService.instance.setEnabled(false);
      }
    });
  }

  Future<void> _updateBiometricSessionIfEnabled(session) async {
    try {
      final enabled = await BiometricService.instance.isEnabled();
      if (enabled && session != null) {
        final accessToken = session.accessToken as String?;
        final refreshToken = session.refreshToken as String?;
        if (accessToken != null &&
            accessToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty) {
          await BiometricService.instance.storeBiometricSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          debugPrint('[main] Biometric session tokens refreshed.');
        }
      }
    } catch (e) {
      debugPrint('[main] Failed to update biometric session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'kriket',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        );
      },
    );
  }
}
