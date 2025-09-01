import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
    // 用于“从服务器同步”的保存：合并本地用户操作字段，避免覆盖
    final emails = await getAllEmails();
    final index = emails.indexWhere((e) => e.messageId == email.messageId);
    
    if (index >= 0) {
      final existing = emails[index];
      final merged = email.copyWith(
        // 保留本地用户操作与衍生字段
        isRead: existing.isRead,
        isStarred: existing.isStarred,
        aiSummary: existing.aiSummary,
        notes: existing.notes,
        createdAt: existing.createdAt,
      );
      emails[index] = merged;
    } else {
      emails.add(email);
    }
    
    await _saveEmailsToFile(emails);
  }
  
  Future<void> updateEmail(EmailMessage email) async {
    // 用于“本地更新”的保存：以传入为准直接更新
    final emails = await getAllEmails();
    final index = emails.indexWhere((e) => e.messageId == email.messageId);
    if (index >= 0) {
      emails[index] = email;
    } else {
      emails.add(email);
    }
    await _saveEmailsToFile(emails);
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
      debugPrint('Error loading emails: $e');
      return [];
    }
  }
  
  // 别名方法，保持兼容性
  Future<List<EmailMessage>> getEmails() async {
    return await getAllEmails();
  }
  
  // 保存邮件列表（批量保存，替换所有邮件）
  Future<void> saveEmails(List<EmailMessage> emails) async {
    await _saveEmailsToFile(emails);
  }
  
  // 批量保存邮件（逐个保存，用于合并模式）
  Future<void> saveEmailsBatch(List<EmailMessage> emails) async {
    for (final email in emails) {
      await saveEmail(email);
    }
  }
  
  // 清除邮件缓存
  Future<void> clearEmailCache() async {
    try {
      final file = File('${_appDir.path}/emails.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing email cache: $e');
    }
  }
  
  // 获取和设置最后同步时间
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _prefs.getInt('last_sync_time');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setInt('last_sync_time', time.millisecondsSinceEpoch);
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
      debugPrint('Error saving emails: $e');
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
  
  // 清理缓存（保留含收藏或笔记的邮件，且仅清正文等大字段）
  Future<void> clearAllData() async {
    try {
      final emails = await getAllEmails();
      final preserved = <EmailMessage>[];
      for (final e in emails) {
        final hasImportant = e.isStarred || (e.notes != null && e.notes!.isNotEmpty);
        if (hasImportant) {
          preserved.add(
            e.copyWith(
              contentHtml: null,
              contentText: null,
              isCached: false,
              // aiSummary/notes/标记等用户数据保留
            ),
          );
        }
      }
      await _saveEmailsToFile(preserved);
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  // 智能清理缓存（删除普通邮件，保留收藏和有笔记的邮件）
  Future<void> clearCachePreservingUserData() async {
    try {
      final allEmails = await getAllEmails();
      
      // 筛选出需要保留的邮件（收藏或有笔记）
      final emailsToKeep = allEmails.where((email) => 
        email.isStarred || (email.notes != null && email.notes!.isNotEmpty)
      ).toList();
      
      // 对于需要保留的邮件，清除其正文内容但保留元数据和用户操作
      final trimmedEmails = emailsToKeep
          .map((e) => e.copyWith(
            contentHtml: null, 
            contentText: null, 
            isCached: false
          ))
          .toList();
      
      // 保存处理后的邮件列表
      await _saveEmailsToFile(trimmedEmails);
      
      final deletedCount = allEmails.length - emailsToKeep.length;
      debugPrint('智能缓存清理完成：删除了 $deletedCount 封普通邮件，保留了 ${emailsToKeep.length} 封重要邮件的元数据');
    } catch (e) {
      debugPrint('清理缓存失败: $e');
      throw Exception('清理缓存失败: $e');
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