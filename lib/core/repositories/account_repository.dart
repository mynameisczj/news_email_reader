import '../models/email_account.dart';
import '../database/database_helper.dart';
import '../services/email_service.dart';

class AccountRepository {
  static final AccountRepository _instance = AccountRepository._internal();
  factory AccountRepository() => _instance;
  AccountRepository._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final EmailService _emailService = EmailService();

  /// 添加邮件账户
  Future<int> addAccount(EmailAccount account) async {
    final database = await _db.database;
    return await database.insert('email_accounts', account.toMap());
  }

  /// 获取所有邮件账户
  Future<List<EmailAccount>> getAllAccounts() async {
    final database = await _db.database;
    final maps = await database.query(
      'email_accounts',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EmailAccount.fromMap(map)).toList();
  }

  /// 获取活跃的邮件账户
  Future<List<EmailAccount>> getActiveAccounts() async {
    final database = await _db.database;
    final maps = await database.query(
      'email_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EmailAccount.fromMap(map)).toList();
  }

  /// 根据ID获取账户
  Future<EmailAccount?> getAccountById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return EmailAccount.fromMap(maps.first);
    }
    
    return null;
  }

  /// 更新账户信息
  Future<int> updateAccount(EmailAccount account) async {
    final database = await _db.database;
    return await database.update(
      'email_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// 删除账户
  Future<int> deleteAccount(int id) async {
    final database = await _db.database;
    
    // 先断开连接
    await _emailService.disconnectAccount(id);
    
    // 删除账户相关的邮件
    await database.delete(
      'emails',
      where: 'account_id = ?',
      whereArgs: [id],
    );
    
    // 删除账户
    return await database.delete(
      'email_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 测试账户连接
  Future<bool> testAccountConnection(EmailAccount account) async {
    return await _emailService.testConnection(account);
  }

  /// 激活/停用账户
  Future<int> toggleAccountStatus(int id, bool isActive) async {
    final database = await _db.database;
    
    if (!isActive) {
      // 如果停用账户，断开连接
      await _emailService.disconnectAccount(id);
    }
    
    return await database.update(
      'email_accounts',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 连接所有活跃账户
  Future<Map<int, bool>> connectAllActiveAccounts() async {
    final accounts = await getActiveAccounts();
    final results = <int, bool>{};
    
    for (final account in accounts) {
      final success = await _emailService.connectAccount(account);
      results[account.id!] = success;
    }
    
    return results;
  }

  /// 根据邮箱地址查找账户
  Future<EmailAccount?> getAccountByEmail(String email) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_accounts',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (maps.isNotEmpty) {
      return EmailAccount.fromMap(maps.first);
    }
    
    return null;
  }

  /// 检查邮箱是否已存在
  Future<bool> emailExists(String email) async {
    final account = await getAccountByEmail(email);
    return account != null;
  }
}