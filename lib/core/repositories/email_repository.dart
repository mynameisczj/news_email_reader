import 'package:sqflite/sqflite.dart';
import '../models/email_message.dart';
import '../models/email_account.dart';
import '../database/database_helper.dart';
import '../services/email_service.dart';
import '../services/whitelist_service.dart';

class EmailRepository {
  static final EmailRepository _instance = EmailRepository._internal();
  factory EmailRepository() => _instance;
  EmailRepository._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final EmailService _emailService = EmailService();
  final WhitelistService _whitelistService = WhitelistService();

  /// 保存邮件到本地数据库
  Future<int> saveEmail(EmailMessage email) async {
    final database = await _db.database;
    return await database.insert(
      'emails',
      email.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量保存邮件
  Future<void> saveEmails(List<EmailMessage> emails) async {
    final database = await _db.database;
    final batch = database.batch();
    
    for (final email in emails) {
      batch.insert(
        'emails',
        email.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  /// 从本地数据库获取邮件列表
  Future<List<EmailMessage>> getLocalEmails({
    int? accountId,
    int limit = 50,
    int offset = 0,
    bool? isRead,
    bool? isStarred,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final database = await _db.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (accountId != null) {
      whereClause += ' AND account_id = ?';
      whereArgs.add(accountId);
    }
    
    if (isRead != null) {
      whereClause += ' AND is_read = ?';
      whereArgs.add(isRead ? 1 : 0);
    }
    
    if (isStarred != null) {
      whereClause += ' AND is_starred = ?';
      whereArgs.add(isStarred ? 1 : 0);
    }
    
    if (startDate != null) {
      whereClause += ' AND received_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND received_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await database.query(
      'emails',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'received_date DESC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => EmailMessage.fromMap(map)).toList();
  }

  /// 同步邮件（从服务器获取并筛选）
  Future<List<EmailMessage>> syncEmails(EmailAccount account) async {
    try {
      // 从邮件服务器获取邮件
      final serverEmails = await _emailService.fetchRecentEmails();
      
      // 通过白名单筛选
      final filteredEmails = await _whitelistService.filterEmails(serverEmails);
      
      // 保存到本地数据库
      await saveEmails(filteredEmails);
      
      return filteredEmails;
    } catch (e) {
      print('同步邮件失败: $e');
      // 如果同步失败，返回本地缓存的邮件
      return await getLocalEmails(accountId: account.id);
    }
  }

  /// 获取邮件详细内容
  Future<EmailMessage?> getEmailContent(int emailId) async {
    final database = await _db.database;
    final maps = await database.query(
      'emails',
      where: 'id = ?',
      whereArgs: [emailId],
    );
    
    if (maps.isNotEmpty) {
      return EmailMessage.fromMap(maps.first);
    }
    
    return null;
  }

  /// 更新邮件状态
  Future<int> updateEmailStatus(
    int emailId, {
    bool? isRead,
    bool? isStarred,
    String? aiSummary,
  }) async {
    final database = await _db.database;
    final Map<String, dynamic> updates = {};
    
    if (isRead != null) {
      updates['is_read'] = isRead ? 1 : 0;
    }
    
    if (isStarred != null) {
      updates['is_starred'] = isStarred ? 1 : 0;
    }
    
    if (aiSummary != null) {
      updates['ai_summary'] = aiSummary;
    }
    
    if (updates.isEmpty) return 0;
    
    return await database.update(
      'emails',
      updates,
      where: 'id = ?',
      whereArgs: [emailId],
    );
  }

  /// 搜索邮件
  Future<List<EmailMessage>> searchEmails(
    String query, {
    int? accountId,
    int limit = 50,
  }) async {
    final database = await _db.database;
    
    String whereClause = '(subject LIKE ? OR sender_name LIKE ? OR sender_email LIKE ? OR content_text LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%', '%$query%'];
    
    if (accountId != null) {
      whereClause += ' AND account_id = ?';
      whereArgs.add(accountId);
    }
    
    final maps = await database.query(
      'emails',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'received_date DESC',
      limit: limit,
    );
    
    return maps.map((map) => EmailMessage.fromMap(map)).toList();
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
    final database = await _db.database;
    
    String whereClause = 'ai_summary IS NOT NULL AND ai_summary != ""';
    List<dynamic> whereArgs = [];
    
    if (accountId != null) {
      whereClause += ' AND account_id = ?';
      whereArgs.add(accountId);
    }
    
    final maps = await database.query(
      'emails',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'received_date DESC',
    );
    
    return maps.map((map) => EmailMessage.fromMap(map)).toList();
  }

  /// 删除邮件
  Future<int> deleteEmail(int emailId) async {
    final database = await _db.database;
    return await database.delete(
      'emails',
      where: 'id = ?',
      whereArgs: [emailId],
    );
  }

  /// 清理过期邮件（保留最近30天）
  Future<int> cleanupOldEmails() async {
    final database = await _db.database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return await database.delete(
      'emails',
      where: 'received_date < ? AND is_starred = 0',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
  }
}