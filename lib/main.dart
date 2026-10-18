import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/service_providers.dart';
import 'core/utils/logger.dart';
import 'features/dashboard/screen/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    Logger.success('Firebase initialized', tag: 'Main');
  } catch (e) {
    Logger.error('Failed to initialize Firebase', tag: 'Main', error: e);
    // Continue app without Firebase
  }

  // Create provider container
  final container = ProviderContainer();
  
  // Initialize Hive
  try {
    final cacheService = container.read(localCacheServiceProvider);
    await cacheService.init();
    Logger.success('Hive initialized', tag: 'Main');
  } catch (e) {
    Logger.error('Failed to initialize Hive', tag: 'Main', error: e);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiLAKES Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
