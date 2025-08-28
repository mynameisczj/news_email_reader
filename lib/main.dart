import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Database
  await DatabaseHelper.instance.database;
  
  runApp(
    const ProviderScope(
      child: NewsEmailReaderApp(),
    ),
  );
}

class NewsEmailReaderApp extends StatelessWidget {
  const NewsEmailReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Email Reader',
      theme: AppTheme.darkTheme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}