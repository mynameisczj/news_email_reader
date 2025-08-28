import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/email_message.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _emailCacheBox = 'email_cache';
  static const String _imageCacheBox = 'image_cache';
  static const String _settingsBox = 'settings';

  Box<Map>? _emailCache;
  Box<List<int>>? _imageCache;
  Box<String>? _settings;

  /// 初始化缓存服务
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    _emailCache = await Hive.openBox<Map>(_emailCacheBox);
    _imageCache = await Hive.openBox<List<int>>(_imageCacheBox);
    _settings = await Hive.openBox<String>(_settingsBox);
  }

  /// 缓存邮件内容
  Future<void> cacheEmail(EmailMessage email) async {
    if (_emailCache == null) await initialize();
    
    final key = 'email_${email.messageId}';
    final emailData = {
      'id': email.id,
      'accountId': email.accountId,
      'messageId': email.messageId,
      'subject': email.subject,
      'senderName': email.senderName,
      'senderEmail': email.senderEmail,
      'recipientEmail': email.recipientEmail,
      'contentText': email.contentText,
      'contentHtml': email.contentHtml,
      'receivedDate': email.receivedDate.toIso8601String(),
      'isRead': email.isRead,
      'isStarred': email.isStarred,
      'isCached': true,
      'aiSummary': email.aiSummary,
      'createdAt': email.createdAt.toIso8601String(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    
    await _emailCache!.put(key, emailData);
  }

  /// 批量缓存邮件
  Future<void> cacheEmails(List<EmailMessage> emails) async {
    if (_emailCache == null) await initialize();
    
    final Map<String, Map> emailsToCache = {};
    
    for (final email in emails) {
      final key = 'email_${email.messageId}';
      final emailData = {
        'id': email.id,
        'accountId': email.accountId,
        'messageId': email.messageId,
        'subject': email.subject,
        'senderName': email.senderName,
        'senderEmail': email.senderEmail,
        'recipientEmail': email.recipientEmail,
        'contentText': email.contentText,
        'contentHtml': email.contentHtml,
        'receivedDate': email.receivedDate.toIso8601String(),
        'isRead': email.isRead,
        'isStarred': email.isStarred,
        'isCached': true,
        'aiSummary': email.aiSummary,
        'createdAt': email.createdAt.toIso8601String(),
        'cachedAt': DateTime.now().toIso8601String(),
      };
      emailsToCache[key] = emailData;
    }
    
    await _emailCache!.putAll(emailsToCache);
  }

  /// 获取缓存的邮件
  Future<EmailMessage?> getCachedEmail(String messageId) async {
    if (_emailCache == null) await initialize();
    
    final key = 'email_$messageId';
    final emailData = _emailCache!.get(key);
    
    if (emailData != null) {
      return EmailMessage(
        id: emailData['id'],
        accountId: emailData['accountId'],
        messageId: emailData['messageId'],
        subject: emailData['subject'],
        senderName: emailData['senderName'],
        senderEmail: emailData['senderEmail'],
        recipientEmail: emailData['recipientEmail'],
        contentText: emailData['contentText'],
        contentHtml: emailData['contentHtml'],
        receivedDate: DateTime.parse(emailData['receivedDate']),
        isRead: emailData['isRead'],
        isStarred: emailData['isStarred'],
        isCached: emailData['isCached'] ?? true,
        aiSummary: emailData['aiSummary'],
        createdAt: DateTime.parse(emailData['createdAt']),
      );
    }
    
    return null;
  }

  /// 获取所有缓存的邮件
  Future<List<EmailMessage>> getAllCachedEmails() async {
    if (_emailCache == null) await initialize();
    
    final emails = <EmailMessage>[];
    
    for (final key in _emailCache!.keys) {
      if (key.toString().startsWith('email_')) {
        final emailData = _emailCache!.get(key);
        if (emailData != null) {
          emails.add(EmailMessage(
            id: emailData['id'],
            accountId: emailData['accountId'],
            messageId: emailData['messageId'],
            subject: emailData['subject'],
            senderName: emailData['senderName'],
            senderEmail: emailData['senderEmail'],
            recipientEmail: emailData['recipientEmail'],
            contentText: emailData['contentText'],
            contentHtml: emailData['contentHtml'],
            receivedDate: DateTime.parse(emailData['receivedDate']),
            isRead: emailData['isRead'],
            isStarred: emailData['isStarred'],
            isCached: emailData['isCached'] ?? true,
            aiSummary: emailData['aiSummary'],
            createdAt: DateTime.parse(emailData['createdAt']),
          ));
        }
      }
    }
    
    // 按接收时间排序
    emails.sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    
    return emails;
  }

  /// 缓存图片
  Future<void> cacheImage(String url, List<int> imageData) async {
    if (_imageCache == null) await initialize();
    
    final key = 'image_${url.hashCode}';
    await _imageCache!.put(key, imageData);
  }

  /// 获取缓存的图片
  Future<List<int>?> getCachedImage(String url) async {
    if (_imageCache == null) await initialize();
    
    final key = 'image_${url.hashCode}';
    return _imageCache!.get(key);
  }

  /// 保存设置
  Future<void> saveSetting(String key, String value) async {
    if (_settings == null) await initialize();
    
    await _settings!.put(key, value);
  }

  /// 获取设置
  Future<String?> getSetting(String key) async {
    if (_settings == null) await initialize();
    
    return _settings!.get(key);
  }

  /// 检查邮件是否已缓存
  Future<bool> isEmailCached(String messageId) async {
    if (_emailCache == null) await initialize();
    
    final key = 'email_$messageId';
    return _emailCache!.containsKey(key);
  }

  /// 删除缓存的邮件
  Future<void> deleteCachedEmail(String messageId) async {
    if (_emailCache == null) await initialize();
    
    final key = 'email_$messageId';
    await _emailCache!.delete(key);
  }

  /// 清理过期缓存
  Future<void> cleanupExpiredCache({int maxDays = 30}) async {
    if (_emailCache == null) await initialize();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: maxDays));
    final keysToDelete = <String>[];
    
    for (final key in _emailCache!.keys) {
      if (key.toString().startsWith('email_')) {
        final emailData = _emailCache!.get(key);
        if (emailData != null && emailData['cachedAt'] != null) {
          final cachedAt = DateTime.parse(emailData['cachedAt']);
          if (cachedAt.isBefore(cutoffDate)) {
            keysToDelete.add(key.toString());
          }
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _emailCache!.delete(key);
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_emailCache == null || _imageCache == null) await initialize();
    
    final emailCount = _emailCache!.keys.where((key) => key.toString().startsWith('email_')).length;
    final imageCount = _imageCache!.keys.length;
    
    // 计算缓存大小（估算）
    int emailCacheSize = 0;
    for (final key in _emailCache!.keys) {
      if (key.toString().startsWith('email_')) {
        final emailData = _emailCache!.get(key);
        if (emailData != null) {
          final jsonString = jsonEncode(emailData);
          emailCacheSize += jsonString.length;
        }
      }
    }
    
    int imageCacheSize = 0;
    for (final key in _imageCache!.keys) {
      final imageData = _imageCache!.get(key);
      if (imageData != null) {
        imageCacheSize += imageData.length;
      }
    }
    
    return {
      'emailCount': emailCount,
      'imageCount': imageCount,
      'emailCacheSize': emailCacheSize,
      'imageCacheSize': imageCacheSize,
      'totalCacheSize': emailCacheSize + imageCacheSize,
    };
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    if (_emailCache == null || _imageCache == null) await initialize();
    
    await _emailCache!.clear();
    await _imageCache!.clear();
  }

  /// 清空邮件缓存
  Future<void> clearEmailCache() async {
    if (_emailCache == null) await initialize();
    
    final keysToDelete = _emailCache!.keys
        .where((key) => key.toString().startsWith('email_'))
        .toList();
    
    for (final key in keysToDelete) {
      await _emailCache!.delete(key);
    }
  }

  /// 清空图片缓存
  Future<void> clearImageCache() async {
    if (_imageCache == null) await initialize();
    
    await _imageCache!.clear();
  }

  /// 导出缓存数据
  Future<Map<String, dynamic>> exportCacheData() async {
    if (_emailCache == null) await initialize();
    
    final emails = <Map<String, dynamic>>[];
    
    for (final key in _emailCache!.keys) {
      if (key.toString().startsWith('email_')) {
        final emailData = _emailCache!.get(key);
        if (emailData != null) {
          emails.add(Map<String, dynamic>.from(emailData));
        }
      }
    }
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'emailCount': emails.length,
      'emails': emails,
    };
  }

  /// 导入缓存数据
  Future<void> importCacheData(Map<String, dynamic> data) async {
    if (_emailCache == null) await initialize();
    
    final emails = data['emails'] as List<dynamic>?;
    if (emails != null) {
      for (final emailData in emails) {
        final messageId = emailData['messageId'];
        if (messageId != null) {
          final key = 'email_$messageId';
          await _emailCache!.put(key, Map<String, dynamic>.from(emailData));
        }
      }
    }
  }

  /// 关闭缓存服务
  Future<void> close() async {
    await _emailCache?.close();
    await _imageCache?.close();
    await _settings?.close();
  }
}