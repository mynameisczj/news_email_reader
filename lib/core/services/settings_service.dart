import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _keyAutoSummary = 'auto_summary';
  static const String _keyBatchSummary = 'batch_summary';
  static const String _keyNotifications = 'notifications';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keyDarkMode = 'dark_mode';

  // 自动生成总结
  Future<bool> getAutoSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSummary) ?? true;
  }

  Future<void> setAutoSummary(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSummary, value);
  }

  // 批量总结
  Future<bool> getBatchSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBatchSummary) ?? false;
  }

  Future<void> setBatchSummary(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBatchSummary, value);
  }

  // 通知设置
  Future<bool> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  // 自动同步
  Future<bool> getAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSync) ?? true;
  }

  Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, value);
  }

  // 深色模式
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }
}