import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/whitelist_rule.dart';
import '../../../../core/services/whitelist_service.dart';

class WhitelistManagementSection extends ConsumerStatefulWidget {
  const WhitelistManagementSection({super.key});

  @override
  ConsumerState<WhitelistManagementSection> createState() => _WhitelistManagementSectionState();
}

class _WhitelistManagementSectionState extends ConsumerState<WhitelistManagementSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WhitelistService _whitelistService = WhitelistService();
  
  List<WhitelistRule> _senderRules = [];
  List<WhitelistRule> _keywordRules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final senderRules = await _whitelistService.getSenderRules();
      final keywordRules = await _whitelistService.getKeywordRules();
      
      setState(() {
        _senderRules = senderRules;
        _keywordRules = keywordRules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载白名单失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            // 导入导出按钮行
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importRules,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('导入'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportRules,
                      icon: const Icon(Icons.file_download),
                      label: const Text('导出'),
                    ),
                  ),
                ],
              ),
            ),
            // Tab栏
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              tabs: const [
                Tab(text: '发件人白名单'),
                Tab(text: '关键词白名单'),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSenderRulesList(),
                _buildKeywordRulesList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRuleDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSenderRulesList() {
    if (_senderRules.isEmpty) {
      return _buildEmptyState('发件人白名单', '添加信任的发件人邮箱地址');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _senderRules.length,
      itemBuilder: (context, index) {
        final rule = _senderRules[index];
        return _buildRuleCard(rule);
      },
    );
  }

  Widget _buildKeywordRulesList() {
    if (_keywordRules.isEmpty) {
      return _buildEmptyState('关键词白名单', '添加邮件筛选关键词');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _keywordRules.length,
      itemBuilder: (context, index) {
        final rule = _keywordRules[index];
        return _buildRuleCard(rule);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.filter_list_off,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无$title',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addCommonRules,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('添加常用规则'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(WhitelistRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showEditRuleDialog(rule),
        leading: CircleAvatar(
          backgroundColor: rule.isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
          child: Icon(
            rule.type == WhitelistType.sender ? Icons.person : Icons.label,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          rule.value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: rule.description != null
            ? Text(rule.description!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: rule.isActive,
              onChanged: (value) => _toggleRuleStatus(rule, value),
              activeThumbColor: AppTheme.primaryColor,
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleRuleAction(value, rule),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('编辑'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleRuleAction(String action, WhitelistRule rule) {
    switch (action) {
      case 'edit':
        _showEditRuleDialog(rule);
        break;
      case 'delete':
        _showDeleteRuleDialog(rule);
        break;
    }
  }

  void _showAddRuleDialog() {
    final currentTab = _tabController.index;
    final ruleType = currentTab == 0 ? WhitelistType.sender : WhitelistType.keyword;
    _showRuleDialog(ruleType: ruleType);
  }

  void _showEditRuleDialog(WhitelistRule rule) {
    _showRuleDialog(rule: rule);
  }

  void _showRuleDialog({WhitelistRule? rule, WhitelistType? ruleType}) {
    final isEditing = rule != null;
    final type = rule?.type ?? ruleType ?? WhitelistType.sender;
    
    final valueController = TextEditingController(text: rule?.value ?? '');
    final descriptionController = TextEditingController(text: rule?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑规则' : '添加规则'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: type == WhitelistType.sender ? '发件人邮箱' : '关键词',
                hintText: type == WhitelistType.sender 
                    ? 'example@domain.com 或 @domain.com'
                    : '新闻、科技、技术等',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '规则说明',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => _saveRule(
              context,
              rule,
              type,
              valueController.text,
              descriptionController.text,
            ),
            child: Text(isEditing ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRule(
    BuildContext context,
    WhitelistRule? existingRule,
    WhitelistType type,
    String value,
    String description,
  ) async {
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入规则值')),
      );
      return;
    }

    Navigator.pop(context);

    try {
      final rule = WhitelistRule(
        id: existingRule?.id,
        type: type,
        value: value,
        description: description.isEmpty ? null : description,
        createdAt: existingRule?.createdAt ?? DateTime.now(),
      );

      if (existingRule != null) {
        await _whitelistService.updateRule(rule);
      } else {
        // 检查规则是否已存在
        final exists = await _whitelistService.ruleExists(type, value);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('规则已存在')),
            );
          }
          return;
        }
        
        await _whitelistService.addRule(rule);
      }

      await _loadRules();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('规则${existingRule != null ? '更新' : '添加'}成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleRuleStatus(WhitelistRule rule, bool isActive) async {
    try {
      final updatedRule = rule.copyWith(isActive: isActive);
      await _whitelistService.updateRule(updatedRule);
      await _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  void _showDeleteRuleDialog(WhitelistRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除规则 "${rule.value}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await _whitelistService.deleteRule(rule.id!);
                await _loadRules();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('规则已删除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _addCommonRules() async {
    try {
      await _whitelistService.addCommonNewsSourceRules();
      await _loadRules();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('常用规则已添加')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  /// 导入白名单规则
  Future<void> _importRules() async {
    try {
      // 这部分代码已被替换为JSON粘贴导入方式
      // 如果需要文件导入功能，请添加file_picker依赖
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导出白名单规则
  Future<void> _exportRules() async {
    try {
      final filePath = await _whitelistService.saveRulesToFile();
      
      if (mounted) {
        // 显示导出成功对话框，提供分享选项
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导出成功'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('白名单规则已导出到:'),
                const SizedBox(height: 8),
                Text(
                  filePath,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(filePath)]);
                },
                child: const Text('分享'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}