import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _keyAutoSummary = 'auto_summary';
  static const String _keyBatchSummary = 'batch_summary';
  static const String _keyNotifications = 'notifications';

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



  // 深色模式
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // 邮件同步设置
  Future<void> setSyncQuantity(int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_quantity', quantity);
  }

  Future<int> getSyncQuantity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sync_quantity') ?? 100;
  }

  Future<void> setSyncTimeRange(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_time_range', days);
  }

  Future<int> getSyncTimeRange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sync_time_range') ?? 30;
  }

  Future<void> setAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', enabled);
  }

  Future<bool> getAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_sync') ?? true;
  }

  Future<void> setSyncOnStartup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_on_startup', enabled);
  }

  Future<bool> getSyncOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sync_on_startup') ?? true;
  }
}