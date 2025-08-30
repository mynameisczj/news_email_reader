import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/providers/theme_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.macOS);
  if (isDesktop) {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Storage Service
  await StorageService.instance.initialize();
  
  runApp(
    const ProviderScope(
      child: NewsEmailReaderApp(),
    ),
  );
}

class NewsEmailReaderApp extends ConsumerWidget {
  const NewsEmailReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'News Email Reader',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
