import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/providers/theme_provider.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
