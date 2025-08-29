import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeNotifier(this._settingsService) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDarkMode = await _settingsService.getDarkMode();
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newTheme;
    await _settingsService.setDarkMode(newTheme == ThemeMode.dark);
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    await _settingsService.setDarkMode(themeMode == ThemeMode.dark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(SettingsService());
});