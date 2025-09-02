import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/whitelist_rule.dart';
import '../models/email_message.dart';
import 'storage_service.dart';

class WhitelistService {
  static final WhitelistService _instance = WhitelistService._internal();
  factory WhitelistService() => _instance;
  WhitelistService._internal();

  final StorageService _storage = StorageService.instance;
  static const String _rulesKey = 'whitelist_rules';

  Future<List<WhitelistRule>> _loadRules() async {
    final jsonStr = await _storage.getString(_rulesKey, defaultValue: '[]');
    final List list = json.decode(jsonStr);
    return list.map((e) => WhitelistRule.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveRules(List<WhitelistRule> rules) async {
    final list = rules.map((r) => r.toMap()).toList();
    await _storage.setString(_rulesKey, json.encode(list));
  }

  int _nextId(List<WhitelistRule> rules) {
    final ids = rules.where((r) => r.id != null).map((r) => r.id!).toList();
    if (ids.isEmpty) return 1;
    ids.sort();
    return ids.last + 1;
  }

  /// 添加白名单规则
  Future<int> addRule(WhitelistRule rule) async {
    final rules = await _loadRules();
    final exists = await ruleExists(rule.type, rule.value);
    if (exists) return rule.id ?? -1;

    final withId = rule.id != null ? rule : rule.copyWith(id: _nextId(rules));
    rules.add(withId);
    await _saveRules(rules);
    return withId.id!;
  }

  /// 获取所有白名单规则（仅激活）
  Future<List<WhitelistRule>> getAllRules() async {
    final rules = await _loadRules();
    rules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rules.where((r) => r.isActive).toList();
  }

  Future<List<WhitelistRule>> getSenderRules() async {
    final rules = await _loadRules();
    rules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rules.where((r) => r.type == WhitelistType.sender).toList();
  }

  Future<List<WhitelistRule>> getKeywordRules() async {
    final rules = await _loadRules();
    rules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rules.where((r) => r.type == WhitelistType.keyword).toList();
  }

  Future<int> updateRule(WhitelistRule rule) async {
    final rules = await _loadRules();
    final idx = rules.indexWhere((r) => r.id == rule.id);
    if (idx < 0) return 0;
    rules[idx] = rule;
    await _saveRules(rules);
    return 1;
  }

  Future<int> deleteRule(int id) async {
    final rules = await _loadRules();
    final before = rules.length;
    rules.removeWhere((r) => r.id == id);
    await _saveRules(rules);
    return before - rules.length;
  }

  /// 检查邮件是否通过白名单筛选
  Future<bool> isEmailAllowed(EmailMessage email) async {
    final rules = await getAllRules();
    if (rules.isEmpty) return true;

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
    final allowed = <EmailMessage>[];
    for (final e in emails) {
      if (await isEmailAllowed(e)) allowed.add(e);
    }
    return allowed;
  }

  /// 预置常用规则
  Future<void> addCommonNewsSourceRules() async {
    final presets = [
      WhitelistRule(type: WhitelistType.sender, value: 'newsletter@', description: '通用新闻邮件', createdAt: DateTime.now()),
      WhitelistRule(type: WhitelistType.sender, value: 'news@', description: '新闻邮件', createdAt: DateTime.now()),
      WhitelistRule(type: WhitelistType.sender, value: 'digest@', description: '摘要邮件', createdAt: DateTime.now()),
      WhitelistRule(type: WhitelistType.keyword, value: '新闻', description: '新闻关键词', createdAt: DateTime.now()),
      WhitelistRule(type: WhitelistType.keyword, value: '科技', description: '科技关键词', createdAt: DateTime.now()),
      WhitelistRule(type: WhitelistType.keyword, value: '技术', description: '技术关键词', createdAt: DateTime.now()),
    ];
    for (final r in presets) {
      await addRule(r);
    }
  }

  Future<bool> ruleExists(WhitelistType type, String value) async {
    final rules = await _loadRules();
    return rules.any((r) => r.type == type && r.value == value);
  }

  /// 导出白名单规则到JSON文件
  Future<String> exportRulesToJson() async {
    final rules = await _loadRules();
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'rules': rules.map((r) => r.toMap()).toList(),
    };
    return json.encode(exportData);
  }

  /// 从JSON字符串导入白名单规则
  Future<int> importRulesFromJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final rulesData = data['rules'] as List<dynamic>?;
      
      if (rulesData == null) {
        throw Exception('JSON格式错误：缺少rules字段');
      }

      final existingRules = await _loadRules();
      int importedCount = 0;
      
      for (final ruleData in rulesData) {
        try {
          final ruleMap = Map<String, dynamic>.from(ruleData);
          final rule = WhitelistRule.fromMap(ruleMap);
          
          // 检查是否已存在相同规则
          final exists = existingRules.any((r) => 
            r.type == rule.type && r.value == rule.value);
          
          if (!exists) {
            // 重新分配ID以避免冲突
            final newRule = rule.copyWith(
              id: null,
              createdAt: DateTime.now(),
            );
            await addRule(newRule);
            importedCount++;
          }
        } catch (e) {
          // 跳过无效的规则，继续处理其他规则
          debugPrint('跳过无效规则: $e');
        }
      }
      
      return importedCount;
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  /// 保存白名单规则到文件
  Future<String> saveRulesToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/whitelist_rules_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final jsonString = await exportRulesToJson();
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw Exception('保存文件失败: $e');
    }
  }

  /// 从文件加载白名单规则
  Future<int> loadRulesFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }
      
      final jsonString = await file.readAsString();
      return await importRulesFromJson(jsonString);
    } catch (e) {
      throw Exception('读取文件失败: $e');
    }
  }

  /// 获取所有规则（包括未激活的）
  Future<List<WhitelistRule>> getAllRulesIncludingInactive() async {
    final rules = await _loadRules();
    rules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rules;
  }

  /// 批量更新规则状态
  Future<void> updateRulesStatus(List<int> ruleIds, bool isActive) async {
    final rules = await _loadRules();
    bool hasChanges = false;
    
    for (int i = 0; i < rules.length; i++) {
      if (ruleIds.contains(rules[i].id)) {
        rules[i] = rules[i].copyWith(isActive: isActive);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await _saveRules(rules);
    }
  }

  /// 批量删除规则
  Future<int> deleteRules(List<int> ruleIds) async {
    final rules = await _loadRules();
    final originalCount = rules.length;
    
    rules.removeWhere((rule) => ruleIds.contains(rule.id));
    await _saveRules(rules);
    
    return originalCount - rules.length;
  }
}