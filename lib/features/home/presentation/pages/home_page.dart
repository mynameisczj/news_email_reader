import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_message.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/repositories/email_repository.dart';
import '../../../../core/repositories/account_repository.dart';
import '../../../../core/services/ai_service.dart';
import '../../../reader/presentation/pages/email_reader_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../notes/presentation/pages/notes_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../help/presentation/pages/help_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  List<EmailMessage> _emails = [];
  final EmailRepository _emailRepository = EmailRepository();
  final AccountRepository _accountRepository = AccountRepository();

  final List<String> _filterTabs = [
    '全部',
    '今日',
    '本周',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncAllActiveAccounts();
      _applyCurrentFilter();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('加载邮件失败', e.toString());
    }
  }

  Future<void> _syncAllActiveAccounts() async {
    final activeAccounts = await _accountRepository.getActiveAccounts();

    if (activeAccounts.isEmpty) {
      if (mounted) {
        _showErrorDialog('未发现邮件账户', '请前往设置添加并启用至少一个邮箱账户。');
      }
      _emails = [];
      return;
    }

    final List<EmailMessage> all = [];
    bool hadAuthError = false;
    for (final account in activeAccounts) {
      try {
        final synced = await _emailRepository.syncEmails(account);
        all.addAll(synced);
      } catch (e) {
        hadAuthError = true;
      }
    }

    // 本地再合并排序（降序）
    all.sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    if (mounted) {
      setState(() {
        _emails = all;
      });
    }

    if (hadAuthError) {
      _showErrorDialog('账户连接失败', '部分账户授权码不正确或服务器不可用，请在设置中检查。');
    }
    if (all.isEmpty) {
      _showErrorDialog('邮箱内容为空', '未从服务器获取到任何邮件，请确认邮箱内是否有内容或稍后重试。');
    }
  }

  void _applyCurrentFilter() async {
    // 直接对内存列表进行筛选
    List<EmailMessage> list = List.of(_emails);
    final now = DateTime.now();

    if (_selectedTabIndex == 1) {
      final start = now.subtract(const Duration(days: 1));
      list = list.where((e) => e.receivedDate.isAfter(start)).toList();
    } else if (_selectedTabIndex == 2) {
      final start = now.subtract(const Duration(days: 7));
      list = list.where((e) => e.receivedDate.isAfter(start)).toList();
    }

    list.sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    if (mounted) {
      setState(() {
        _emails = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _buildEmailList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('新闻邮件'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_emails.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterTabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedTabIndex;
          return GestureDetector(
            onTap: () {
              if (_selectedTabIndex != index) {
                setState(() {
                  _selectedTabIndex = index;
                });
                _applyCurrentFilter();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                child: Text(_filterTabs[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailList() {
    if (_isLoading && _emails.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无邮件',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下拉刷新或检查网络连接',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshEmails();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _emails.length,
        itemBuilder: (context, index) {
          final email = _emails[index];
          return _buildEmailCard(email);
        },
      ),
    );
  }

  Widget _buildEmailCard(EmailMessage email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _showEmailOptions(email),
        child: InkWell(
          onTap: () => _openEmailReader(email),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: email.isRead ? null : Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        (email.senderName?.isNotEmpty == true) ? email.senderName![0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.senderName ?? '未知发件人',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            email.senderEmail,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(email.receivedDate),
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (email.isStarred)
                      const Icon(
                        Icons.star,
                        color: AppTheme.secondaryColor,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  email.subject,
                  style: TextStyle(
                    fontWeight: email.isRead ? FontWeight.normal : FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email.contentText ?? '无内容',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '新闻',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (email.aiSummary != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 10,
                              color: AppTheme.secondaryColor,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'AI总结',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _refreshEmails,
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  Future<void> _refreshEmails() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _syncAllActiveAccounts();
      _applyCurrentFilter();

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('邮件已刷新'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        _showErrorDialog('刷新失败', e.toString());
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  void _openEmailReader(EmailMessage email) {
    Navigator.push(
      context,
      AnimationUtils.createPageRoute(
        page: EmailReaderPage(email: email),
        type: PageTransitionType.slideFromRight,
      ),
    );
  }

  Future<void> _toggleStar(EmailMessage email) async {
    try {
      await _emailRepository.updateEmailStatus(
        email.messageId,
        isStarred: !email.isStarred,
      );
      await _loadEmails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            email.isStarred ? '已取消收藏' : '已收藏邮件',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      _showErrorSnack('操作失败: $e');
    }
  }

  void _showEmailOptions(EmailMessage emailData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: Text(emailData.isRead ? '标记为未读' : '标记为已读'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _emailRepository.updateEmailStatus(
                    emailData.messageId,
                    isRead: !emailData.isRead,
                  );
                  await _loadEmails();
                } catch (e) {
                  _showErrorSnack('操作失败: $e');
                }
              },
            ),
            ListTile(
              leading: Icon(emailData.isStarred ? Icons.star_border : Icons.star),
              title: Text(emailData.isStarred ? '取消收藏' : '收藏'),
              onTap: () {
                Navigator.pop(context);
                _toggleStar(emailData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI总结'),
              onTap: () {
                Navigator.pop(context);
                _generateAISummary(emailData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('翻译'),
              onTap: () {
                Navigator.pop(context);
                _translateEmail(emailData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                _shareEmail(emailData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteEmail(emailData);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generateAISummary(EmailMessage emailData) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成AI总结...')),
    );

    try {
      final aiService = AIService();
      final content = emailData.contentText ?? emailData.contentHtml ?? '';
      final summary = await aiService.generateSummary(emailData.subject, content);
      await _emailRepository.updateEmailStatus(emailData.messageId, aiSummary: summary);
      await _loadEmails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI总结已生成')),
        );
      }
    } catch (e) {
      _showErrorSnack('生成总结失败: $e');
    }
  }

  void _translateEmail(EmailMessage emailData) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('翻译功能开发中...')),
    );
  }

  void _shareEmail(EmailMessage emailData) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }

  Future<void> _deleteEmail(EmailMessage emailData) async {
    try {
      await _emailRepository.deleteEmail(emailData.messageId);
      await _loadEmails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除邮件: ${emailData.subject}'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              // TODO: 撤销删除操作
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorSnack('删除失败: $e');
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.email,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '新闻邮件阅读器',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'v0.2.1',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inbox),
            title: const Text('邮件列表'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('我的笔记'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotesPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('收藏邮件'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('帮助'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '新闻邮件阅读器',
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
        Text('• 笔记功能'),
      ],
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
    }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
  }
}