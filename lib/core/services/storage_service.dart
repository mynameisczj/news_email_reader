import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_message.dart';

class StorageService {
  static const String _emailsKey = 'emails';
  static const String _notesKey = 'notes';
  static const String _favoritesKey = 'favorites';
  
  late SharedPreferences _prefs;
  late Directory _appDir;
  
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();
  }
  
  // 邮件存储
  Future<void> saveEmail(EmailMessage email) async {
    final emails = await getAllEmails();
    final index = emails.indexWhere((e) => e.messageId == email.messageId);
    
    if (index >= 0) {
      emails[index] = email;
    } else {
      emails.add(email);
    }
    
    await _saveEmailsToFile(emails);
  }
  
  Future<void> updateEmail(EmailMessage email) async {
    await saveEmail(email);
  }
  
  Future<List<EmailMessage>> getAllEmails() async {
    try {
      final file = File('${_appDir.path}/emails.json');
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) => EmailMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error loading emails: $e');
      return [];
    }
  }
  
  Future<EmailMessage?> getEmailById(String id) async {
    final emails = await getAllEmails();
    try {
      return emails.firstWhere((email) => email.messageId == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<EmailMessage>> getFavoriteEmails() async {
    final emails = await getAllEmails();
    return emails.where((email) => email.isStarred).toList();
  }
  
  Future<List<EmailMessage>> getEmailsWithNotes() async {
    final emails = await getAllEmails();
    return emails.where((email) => email.notes != null && email.notes!.isNotEmpty).toList();
  }
  
  Future<void> deleteEmail(String id) async {
    final emails = await getAllEmails();
    emails.removeWhere((email) => email.messageId == id);
    await _saveEmailsToFile(emails);
  }
  
  Future<void> _saveEmailsToFile(List<EmailMessage> emails) async {
    try {
      final file = File('${_appDir.path}/emails.json');
      final jsonList = emails.map((email) => email.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving emails: $e');
      throw Exception('Failed to save emails: $e');
    }
  }
  
  // 设置存储
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _prefs.getBool(key) ?? defaultValue;
  }
  
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  Future<String> getString(String key, {String defaultValue = ''}) async {
    return _prefs.getString(key) ?? defaultValue;
  }
  
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    return _prefs.getInt(key) ?? defaultValue;
  }
  
  // 清理缓存
  Future<void> clearAllData() async {
    await _prefs.clear();
    
    try {
      final emailsFile = File('${_appDir.path}/emails.json');
      if (await emailsFile.exists()) {
        await emailsFile.delete();
      }
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
  
  // 获取缓存大小
  Future<String> getCacheSize() async {
    try {
      int totalSize = 0;
      
      final emailsFile = File('${_appDir.path}/emails.json');
      if (await emailsFile.exists()) {
        totalSize += await emailsFile.length();
      }
      
      // 转换为可读格式
      if (totalSize < 1024) {
        return '${totalSize}B';
      } else if (totalSize < 1024 * 1024) {
        return '${(totalSize / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return '未知';
    }
  }
}