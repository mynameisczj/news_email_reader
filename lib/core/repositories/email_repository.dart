import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/email_message.dart';
import '../models/email_account.dart';
import '../services/storage_service.dart';
import '../services/email_service.dart';
import '../services/whitelist_service.dart';

class EmailRepository {
  static final EmailRepository _instance = EmailRepository._internal();
  factory EmailRepository() => _instance;
  EmailRepository._internal();

  final StorageService _storage = StorageService.instance;
  final EmailService _emailService = EmailService();
  final WhitelistService _whitelistService = WhitelistService();

  /// 保存邮件到本地存储
  Future<void> saveEmail(EmailMessage email) async {
    await _storage.saveEmail(email);
  }

  /// 批量保存邮件
  Future<void> saveEmails(List<EmailMessage> emails) async {
    for (final email in emails) {
      await _storage.saveEmail(email);
    }
  }

  /// 从本地存储获取邮件列表
  Future<List<EmailMessage>> getLocalEmails({
    int? accountId,
    int limit = 50,
    int offset = 0,
    bool? isRead,
    bool? isStarred,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<EmailMessage> emails = await _storage.getAllEmails();
    
    // 应用筛选条件
    if (accountId != null) {
      emails = emails.where((email) => email.accountId == accountId).toList();
    }
    
    if (isRead != null) {
      emails = emails.where((email) => email.isRead == isRead).toList();
    }
    
    if (isStarred != null) {
      emails = emails.where((email) => email.isStarred == isStarred).toList();
    }
    
    if (startDate != null) {
      emails = emails.where((email) => email.receivedDate.isAfter(startDate) || email.receivedDate.isAtSameMomentAs(startDate)).toList();
    }
    
    if (endDate != null) {
      emails = emails.where((email) => email.receivedDate.isBefore(endDate) || email.receivedDate.isAtSameMomentAs(endDate)).toList();
    }
    
    // 按接收时间降序排序
    emails.sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    
    // 应用分页
    if (offset > 0) {
      emails = emails.skip(offset).toList();
    }
    if (limit > 0 && emails.length > limit) {
      emails = emails.take(limit).toList();
    }
    
    return emails;
  }

  /// 同步邮件（从服务器获取并筛选）
  Future<List<EmailMessage>> syncEmails(EmailAccount account) async {
    try {
      // 从邮件服务器获取邮件
      final serverEmails = await _emailService.fetchRecentEmails();
      
      // 通过白名单筛选
      final filteredEmails = await _whitelistService.filterEmails(serverEmails);
      
      // 保存到本地存储
      await saveEmails(filteredEmails);
      
      return filteredEmails;
    } catch (e) {
      print('同步邮件失败: $e');
      // 如果同步失败，返回本地缓存的邮件
      return await getLocalEmails(accountId: account.id);
    }
  }

  /// 获取邮件详细内容
  Future<EmailMessage?> getEmailContent(String emailId) async {
    return await _storage.getEmailById(emailId);
  }

  /// 更新邮件状态
  Future<void> updateEmailStatus(
    String emailId, {
    bool? isRead,
    bool? isStarred,
    String? aiSummary,
  }) async {
    final email = await _storage.getEmailById(emailId);
    if (email == null) return;
    
    final updatedEmail = email.copyWith(
      isRead: isRead ?? email.isRead,
      isStarred: isStarred ?? email.isStarred,
      aiSummary: aiSummary ?? email.aiSummary,
    );
    
    await _storage.updateEmail(updatedEmail);
  }

  /// 更新邮件
  Future<void> updateEmail(EmailMessage email) async {
    await _storage.updateEmail(email);
  }

  /// 搜索邮件
  Future<List<EmailMessage>> searchEmails(
    String query, {
    int? accountId,
    int limit = 50,
  }) async {
    List<EmailMessage> emails = await _storage.getAllEmails();
    
    // 应用账户筛选
    if (accountId != null) {
      emails = emails.where((email) => email.accountId == accountId).toList();
    }
    
    // 搜索匹配
    final lowerQuery = query.toLowerCase();
    emails = emails.where((email) {
      return email.subject.toLowerCase().contains(lowerQuery) ||
             (email.senderName?.toLowerCase().contains(lowerQuery) ?? false) ||
             email.senderEmail.toLowerCase().contains(lowerQuery) ||
             (email.contentText?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
    
    // 按接收时间降序排序
    emails.sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    
    // 应用限制
    if (limit > 0 && emails.length > limit) {
      emails = emails.take(limit).toList();
    }
    
    return emails;
  }

  /// 获取今日邮件
  Future<List<EmailMessage>> getTodayEmails({int? accountId}) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await getLocalEmails(
      accountId: accountId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// 获取本周邮件
  Future<List<EmailMessage>> getWeekEmails({int? accountId}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return await getLocalEmails(
      accountId: accountId,
      startDate: startOfWeekDay,
    );
  }

  /// 获取已总结的邮件
  Future<List<EmailMessage>> getSummarizedEmails({int? accountId}) async {
    List<EmailMessage> emails = await _storage.getAllEmails();
    
    // 筛选有AI总结的邮件
    emails = emails.where((email) => 
      email.aiSummary != null && email.aiSummary!.isNotEmpty
    ).toList();
    
    // 应用账户筛选
    if (accountId != null) {
      emails = emails.where((email) => email.accountId == accountId).toList();
    }
    
    // 按接收时间降序排序
    emails.sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    
    return emails;
  }

  /// 删除邮件
  Future<void> deleteEmail(String emailId) async {
    await _storage.deleteEmail(emailId);
  }

  /// 清理过期邮件（保留最近30天）
  Future<int> cleanupOldEmails() async {
    final emails = await _storage.getAllEmails();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    int deletedCount = 0;
    for (final email in emails) {
      if (email.receivedDate.isBefore(thirtyDaysAgo) && !email.isStarred) {
        await _storage.deleteEmail(email.messageId);
        deletedCount++;
      }
    }
    
    return deletedCount;
  }

  /// 获取收藏的邮件
  Future<List<EmailMessage>> getStarredEmails() async {
    return await _storage.getFavoriteEmails();
  }

  /// 获取收藏的邮件（别名方法）
  Future<List<EmailMessage>> getFavoriteEmails() async {
    return await getStarredEmails();
  }

  /// 获取有笔记的邮件
  Future<List<EmailMessage>> getEmailsWithNotes() async {
    return await _storage.getEmailsWithNotes();
  }
}

// Provider for EmailRepository
final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  return EmailRepository();
});