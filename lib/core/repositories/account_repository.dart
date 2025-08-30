import '../database/database_helper.dart';
import '../models/email_account.dart';
import '../services/email_service.dart';

/// 当尝试添加或更新一个已存在的账户时抛出此异常
class DuplicateAccountException implements Exception {
  final String message;
  DuplicateAccountException(this.message);

  @override
  String toString() => message;
}

class AccountRepository {
  static final AccountRepository _instance = AccountRepository._internal();
  factory AccountRepository() => _instance;
  AccountRepository._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final EmailService _emailService = EmailService();

  /// 检查具有相同唯一标识（邮箱、服务器、协议）的账户是否已存在
  Future<bool> accountExists({
    required String email,
    required String serverHost,
    required String protocol,
    int? excludeId, // 在更新时排除当前账户ID
  }) async {
    final allAccounts = await getAllAccounts();
    final lowerEmail = email.toLowerCase();
    final lowerHost = serverHost.toLowerCase();
    final upperProtocol = protocol.toUpperCase();

    for (final account in allAccounts) {
      if (excludeId != null && account.id == excludeId) {
        continue; // 这是同一个账户，跳过
      }
      if (account.email.toLowerCase() == lowerEmail &&
          account.serverHost.toLowerCase() == lowerHost &&
          account.protocol.toUpperCase() == upperProtocol) {
        return true; // 发现重复
      }
    }
    return false;
  }

  /// 获取所有邮件账户
  Future<List<EmailAccount>> getAllAccounts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('email_accounts');
    
    return List.generate(maps.length, (i) {
      return EmailAccount.fromMap(maps[i]);
    });
  }

  /// 根据ID获取账户
  Future<EmailAccount?> getAccountById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'email_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return EmailAccount.fromMap(maps.first);
    }
    return null;
  }

  /// 添加新账户
  Future<int> addAccount(EmailAccount account) async {
    final duplicated = await accountExists(
      email: account.email,
      serverHost: account.serverHost,
      protocol: account.protocol,
    );
    if (duplicated) {
      throw DuplicateAccountException(
        '该账户已存在：${account.email} (${account.protocol}@${account.serverHost})。\\n建议：编辑已存在账户、停用后再添加，或删除重复账户。',
      );
    }
    final db = await _databaseHelper.database;
    return await db.insert('email_accounts', account.toMap());
  }

  /// 更新账户
  Future<int> updateAccount(EmailAccount account) async {
    final duplicated = await accountExists(
      email: account.email,
      serverHost: account.serverHost,
      protocol: account.protocol,
      excludeId: account.id,
    );
    if (duplicated) {
      throw DuplicateAccountException(
        '存在相同邮箱与服务器的账户，无法保存：${account.email} (${account.protocol}@${account.serverHost})。\\n建议：调整显示名称或修改协议/服务器配置，避免重复。',
      );
    }
    final db = await _databaseHelper.database;
    return await db.update(
      'email_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// 删除账户
  Future<int> deleteAccount(int id) async {
    final db = await _databaseHelper.database;
    
    // 先删除相关的邮件
    await db.delete(
      'emails',
      where: 'account_id = ?',
      whereArgs: [id],
    );
    
    // 再删除账户
    return await db.delete(
      'email_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 激活账户
  Future<bool> activateAccount(int id) async {
    final account = await getAccountById(id);
    if (account == null) return false;

    try {
      // 连接到邮件服务器
      final success = await _emailService.connectToAccount(account);
      if (success) {
        // 更新账户状态为激活
        final updatedAccount = account.copyWith(isActive: true);
        await updateAccount(updatedAccount);
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Error activating account: $e');
      return false;
    }
  }

  /// 停用账户
  Future<void> deactivateAccount(int id) async {
    final account = await getAccountById(id);
    if (account == null) return;

    // 断开连接
    await _emailService.disconnect();
    
    // 更新账户状态为停用
    final updatedAccount = account.copyWith(isActive: false);
    await updateAccount(updatedAccount);
  }

  /// 测试账户连接
  Future<bool> testAccountConnection(EmailAccount account) async {
    return await _emailService.connectToAccount(account);
  }

  /// 获取激活的账户
  Future<List<EmailAccount>> getActiveAccounts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'email_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    
    return List.generate(maps.length, (i) {
      return EmailAccount.fromMap(maps[i]);
    });
  }

  /// 停用账户时断开连接
  Future<void> deactivateAccountWithDisconnect(int id) async {
    // 如果停用账户，断开连接
    await _emailService.disconnect();
    
    final account = await getAccountById(id);
    if (account != null) {
      final updatedAccount = account.copyWith(isActive: false);
      await updateAccount(updatedAccount);
    }
  }

  /// 连接所有激活的账户
  Future<Map<int, bool>> connectAllActiveAccounts() async {
    final accounts = await getActiveAccounts();
    final Map<int, bool> results = {};
    
    for (final account in accounts) {
      final success = await _emailService.connectToAccount(account);
      results[account.id!] = success;
      if (!success) {
        // ignore: avoid_print
        print('Failed to connect account: ${account.email}');
      }
    }
    
    return results;
  }

  /// 验证账户配置
  Future<bool> validateAccountConfig(EmailAccount account) async {
    // 基本验证
    if (account.email.isEmpty || 
        account.serverHost.isEmpty || 
        account.password.isEmpty) {
      return false;
    }

    // 邮箱格式验证
    final emailRegex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
    if (!emailRegex.hasMatch(account.email)) {
      return false;
    }

    return true;
  }

  /// 获取账户统计信息
  Future<Map<String, int>> getAccountStats(int accountId) async {
    final db = await _databaseHelper.database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM emails WHERE account_id = ?',
      [accountId],
    );
    
    final unreadResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM emails WHERE account_id = ? AND is_read = 0',
      [accountId],
    );
    
    final starredResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM emails WHERE account_id = ? AND is_starred = 1',
      [accountId],
    );

    return {
      'total': totalResult.first['count'] as int,
      'unread': unreadResult.first['count'] as int,
      'starred': starredResult.first['count'] as int,
    };
  }
}