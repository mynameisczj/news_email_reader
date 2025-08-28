import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_account.dart';
import '../../../../core/models/whitelist_rule.dart';
import '../../../../core/services/ai_service.dart';
import '../widgets/account_management_section.dart';
import '../widgets/whitelist_management_section.dart';
import '../widgets/ai_settings_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AccountManagementSection(),
          WhitelistManagementSection(),
          AISettingsSection(),
          AppSettingsSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('设置'),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.email),
            text: '账户',
          ),
          Tab(
            icon: Icon(Icons.filter_list),
            text: '白名单',
          ),
          Tab(
            icon: Icon(Icons.auto_awesome),
            text: 'AI设置',
          ),
          Tab(
            icon: Icon(Icons.settings),
            text: '应用',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AppSettingsSection extends ConsumerWidget {
  const AppSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsGroup(
          title: '通用设置',
          children: [
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: '深色模式',
              subtitle: '使用深色主题',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: 切换主题
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            _buildSettingsTile(
              icon: Icons.notifications,
              title: '推送通知',
              subtitle: '接收新邮件通知',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: 切换通知
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            _buildSettingsTile(
              icon: Icons.sync,
              title: '自动同步',
              subtitle: '定期同步邮件',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: 切换自动同步
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsGroup(
          title: '缓存设置',
          children: [
            _buildSettingsTile(
              icon: Icons.storage,
              title: '缓存大小',
              subtitle: '当前缓存: 128 MB',
              onTap: () {
                // TODO: 显示缓存详情
              },
            ),
            _buildSettingsTile(
              icon: Icons.clear_all,
              title: '清理缓存',
              subtitle: '清除所有缓存数据',
              onTap: () {
                _showClearCacheDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsGroup(
          title: '关于',
          children: [
            _buildSettingsTile(
              icon: Icons.info,
              title: '版本信息',
              subtitle: '极客新闻邮件阅读器 v1.0.0',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            _buildSettingsTile(
              icon: Icons.help,
              title: '帮助与反馈',
              subtitle: '使用帮助和问题反馈',
              onTap: () {
                // TODO: 打开帮助页面
              },
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: '隐私政策',
              subtitle: '查看隐私政策',
              onTap: () {
                // TODO: 打开隐私政策
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.textPrimaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清除所有缓存数据吗？这将删除已下载的邮件内容和图片。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 执行清理缓存
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清理')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '极客新闻邮件阅读器',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.email,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: const [
        Text('专为极客用户设计的新闻邮件阅读应用'),
        SizedBox(height: 16),
        Text('功能特性：'),
        Text('• 多协议邮件支持'),
        Text('• 智能白名单筛选'),
        Text('• AI邮件总结'),
        Text('• 纯净阅读体验'),
      ],
    );
  }
}