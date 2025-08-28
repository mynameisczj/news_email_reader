import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_message.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../reader/presentation/pages/email_reader_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTabIndex = 0;
  
  final List<String> _filterTabs = [
    '全部',
    '今日',
    '本周',
    '已总结',
    '已收藏',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
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
            child: const Text(
              '12',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          // TODO: 打开侧边栏
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: 搜索功能
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
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
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
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
    // 模拟邮件数据
    final mockEmails = List.generate(10, (index) => {
      'id': index,
      'subject': '科技日报 - 人工智能最新进展 ${index + 1}',
      'sender': 'tech@example.com',
      'senderName': '科技日报',
      'preview': '本期内容包括：OpenAI发布最新模型、谷歌AI突破性进展、苹果智能功能更新...',
      'time': '${2 + index}小时前',
      'isRead': index % 3 == 0,
      'isStarred': index % 5 == 0,
      'hasSummary': index % 4 == 0,
      'category': '科技',
    });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockEmails.length,
      itemBuilder: (context, index) {
        final email = mockEmails[index];
        return _buildEmailCard(email);
      },
    );
  }
  
  Widget _buildEmailCard(Map<String, dynamic> email) {
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
              color: email['isRead'] ? null : Theme.of(context).primaryColor.withOpacity(0.05),
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
                      email['senderName'][0],
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
                          email['senderName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          email['sender'],
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    email['time'],
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (email['isStarred'])
                    const Icon(
                      Icons.star,
                      color: AppTheme.secondaryColor,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                email['subject'],
                style: TextStyle(
                  fontWeight: email['isRead'] ? FontWeight.normal : FontWeight.w500,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email['preview'],
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
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      email['category'],
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (email['hasSummary'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
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

  void _refreshEmails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在刷新邮件...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    setState(() {
      // 触发重建以显示加载状态
    });
  }

  void _openEmailReader(Map<String, dynamic> emailData) {
    // 创建模拟的EmailMessage对象
    final email = EmailMessage(
      accountId: 1,
      messageId: 'msg_${emailData['id']}',
      subject: emailData['subject'],
      senderName: emailData['senderName'],
      senderEmail: emailData['sender'],
      contentText: emailData['preview'],
      contentHtml: '<p>${emailData['preview']}</p>',
      receivedDate: DateTime.now().subtract(Duration(hours: emailData['id'] + 1)),
      isRead: emailData['isRead'],
      isStarred: emailData['isStarred'],
      aiSummary: emailData['hasSummary'] ? '这是一篇关于${emailData['category']}的新闻邮件，包含了最新的行业动态和技术进展。' : null,
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      AnimationUtils.createPageRoute(
        page: EmailReaderPage(email: email),
        type: PageTransitionType.slideFromRight,
      ),
    );
  }

  void _toggleStar(Map<String, dynamic> emailData) {
    setState(() {
      emailData['isStarred'] = !emailData['isStarred'];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          emailData['isStarred'] ? '已收藏邮件' : '已取消收藏',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showEmailOptions(Map<String, dynamic> emailData) {
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
              title: Text(emailData['isRead'] ? '标记为未读' : '标记为已读'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  emailData['isRead'] = !emailData['isRead'];
                });
              },
            ),
            ListTile(
              leading: Icon(emailData['isStarred'] ? Icons.star_border : Icons.star),
              title: Text(emailData['isStarred'] ? '取消收藏' : '收藏'),
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

  void _generateAISummary(Map<String, dynamic> emailData) {
    // TODO: 实现AI总结功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成AI总结...')),
    );
  }

  void _translateEmail(Map<String, dynamic> emailData) {
    // TODO: 实现翻译功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在翻译邮件...')),
    );
  }

  void _shareEmail(Map<String, dynamic> emailData) {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }

  void _deleteEmail(Map<String, dynamic> emailData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除邮件: ${emailData['subject']}'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            // TODO: 撤销删除操作
          },
        ),
      ),
    );
  }
}
