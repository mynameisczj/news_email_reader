import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/theme_provider.dart';
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

class AppSettingsSection extends ConsumerStatefulWidget {
  const AppSettingsSection({super.key});

  @override
  ConsumerState<AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends ConsumerState<AppSettingsSection> {
  final SettingsService _settingsService = SettingsService();
  final StorageService _storageService = StorageService.instance;
  
  bool _darkMode = true;
  bool _notifications = true;
  bool _autoSync = true;
  String _cacheSize = '计算中...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheSize();
  }

  Future<void> _loadSettings() async {
    final darkMode = await _settingsService.getDarkMode();
    final notifications = await _settingsService.getNotifications();
    final autoSync = await _settingsService.getAutoSync();
    
    setState(() {
      _darkMode = darkMode;
      _notifications = notifications;
      _autoSync = autoSync;
    });
  }

  Future<void> _loadCacheSize() async {
    final size = await _storageService.getCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsGroup(
          title: '通用设置',
          children: [
            Consumer(
              builder: (context, ref, child) {
                final themeMode = ref.watch(themeProvider);
                final isDarkMode = themeMode == ThemeMode.dark;
                
                return _buildSettingsTile(
                  icon: Icons.dark_mode,
                  title: '深色模式',
                  subtitle: '使用深色主题',
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.notifications,
              title: '推送通知',
              subtitle: '接收新邮件通知',
              trailing: Switch(
                value: _notifications,
                onChanged: (value) async {
                  await _settingsService.setNotifications(value);
                  setState(() {
                    _notifications = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            _buildSettingsTile(
              icon: Icons.sync,
              title: '自动同步',
              subtitle: '定期同步邮件',
              trailing: Switch(
                value: _autoSync,
                onChanged: (value) async {
                  await _settingsService.setAutoSync(value);
                  setState(() {
                    _autoSync = value;
                  });
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
              subtitle: '当前缓存: $_cacheSize',
              onTap: () {
                _loadCacheSize(); // 刷新缓存大小
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
              subtitle: '极客新闻邮件阅读器 v0.2.1',
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _storageService.clearAllData();
                await _loadCacheSize(); // 刷新缓存大小显示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清理')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('清理缓存失败: $e')),
                );
              }
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
      applicationVersion: '0.2.1',
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