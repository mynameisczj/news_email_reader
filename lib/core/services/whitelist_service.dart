import '../models/whitelist_rule.dart';
import '../models/email_message.dart';
import '../database/database_helper.dart';

class WhitelistService {
  static final WhitelistService _instance = WhitelistService._internal();
  factory WhitelistService() => _instance;
  WhitelistService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 添加白名单规则
  Future<int> addRule(WhitelistRule rule) async {
    final database = await _db.database;
    return await database.insert('whitelist', rule.toMap());
  }

  /// 获取所有白名单规则
  Future<List<WhitelistRule>> getAllRules() async {
    final database = await _db.database;
    final maps = await database.query(
      'whitelist',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WhitelistRule.fromMap(map)).toList();
  }

  /// 获取发件人白名单
  Future<List<WhitelistRule>> getSenderRules() async {
    final database = await _db.database;
    final maps = await database.query(
      'whitelist',
      where: 'type = ? AND is_active = ?',
      whereArgs: ['sender', 1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WhitelistRule.fromMap(map)).toList();
  }

  /// 获取关键词白名单
  Future<List<WhitelistRule>> getKeywordRules() async {
    final database = await _db.database;
    final maps = await database.query(
      'whitelist',
      where: 'type = ? AND is_active = ?',
      whereArgs: ['keyword', 1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WhitelistRule.fromMap(map)).toList();
  }

  /// 更新白名单规则
  Future<int> updateRule(WhitelistRule rule) async {
    final database = await _db.database;
    return await database.update(
      'whitelist',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  /// 删除白名单规则
  Future<int> deleteRule(int id) async {
    final database = await _db.database;
    return await database.delete(
      'whitelist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查邮件是否通过白名单筛选
  Future<bool> isEmailAllowed(EmailMessage email) async {
    final rules = await getAllRules();
    
    if (rules.isEmpty) {
      // 如果没有白名单规则，默认允许所有邮件
      return true;
    }

    final content = '${email.contentText ?? ''} ${email.contentHtml ?? ''}';
    
    for (final rule in rules) {
      if (rule.matches(email.senderEmail, email.subject, content)) {
        return true;
      }
    }

    return false;
  }

  /// 批量筛选邮件
  Future<List<EmailMessage>> filterEmails(List<EmailMessage> emails) async {
    final allowedEmails = <EmailMessage>[];
    
    for (final email in emails) {
      if (await isEmailAllowed(email)) {
        allowedEmails.add(email);
      }
    }
    
    return allowedEmails;
  }

  /// 添加常用新闻源白名单
  Future<void> addCommonNewsSourceRules() async {
    final commonSources = [
      WhitelistRule(
        type: WhitelistType.sender,
        value: 'newsletter@',
        description: '通用新闻邮件',
        createdAt: DateTime.now(),
      ),
      WhitelistRule(
        type: WhitelistType.sender,
        value: 'news@',
        description: '新闻邮件',
        createdAt: DateTime.now(),
      ),
      WhitelistRule(
        type: WhitelistType.sender,
        value: 'digest@',
        description: '摘要邮件',
        createdAt: DateTime.now(),
      ),
      WhitelistRule(
        type: WhitelistType.keyword,
        value: '新闻',
        description: '新闻关键词',
        createdAt: DateTime.now(),
      ),
      WhitelistRule(
        type: WhitelistType.keyword,
        value: '科技',
        description: '科技关键词',
        createdAt: DateTime.now(),
      ),
      WhitelistRule(
        type: WhitelistType.keyword,
        value: '技术',
        description: '技术关键词',
        createdAt: DateTime.now(),
      ),
    ];

    for (final rule in commonSources) {
      await addRule(rule);
    }
  }

  /// 检查规则是否已存在
  Future<bool> ruleExists(WhitelistType type, String value) async {
    final database = await _db.database;
    final maps = await database.query(
      'whitelist',
      where: 'type = ? AND value = ?',
      whereArgs: [type == WhitelistType.sender ? 'sender' : 'keyword', value],
    );
    return maps.isNotEmpty;
  }
}