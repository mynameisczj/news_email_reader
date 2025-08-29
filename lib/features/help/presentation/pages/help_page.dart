import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            '基本功能',
            [
              '• 查看邮件列表：在主页面可以看到所有新闻邮件',
              '• 阅读邮件：点击邮件卡片进入详细阅读页面',
              '• 搜索邮件：点击右上角搜索图标搜索邮件',
              '• 收藏邮件：在邮件详情页点击星标收藏邮件',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'AI功能',
            [
              '• AI总结：在邮件详情页点击"AI总结"按钮生成邮件摘要',
              '• 批量总结：可以对多封邮件进行批量AI总结',
              '• 自定义API：在设置中配置自己的AI服务API',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            '笔记功能',
            [
              '• 添加笔记：在邮件详情页可以为邮件添加个人笔记',
              '• 查看笔记：通过侧边栏进入"我的笔记"查看所有笔记',
              '• 编辑笔记：点击笔记可以进行编辑和修改',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            '收藏管理',
            [
              '• 收藏邮件：在邮件详情页点击星标图标收藏邮件',
              '• 查看收藏：通过侧边栏进入"收藏邮件"查看所有收藏',
              '• 取消收藏：在收藏页面或邮件详情页取消收藏',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            '设置选项',
            [
              '• 主题切换：在设置中可以切换浅色/深色主题',
              '• 邮箱管理：添加和管理多个邮箱账户',
              '• 白名单设置：设置发件人和关键词白名单',
              '• AI配置：配置AI服务的API密钥和参数',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            '常见问题',
            [
              'Q: 如何添加邮箱账户？\nA: 进入设置 > 邮箱管理，点击添加按钮配置邮箱信息。',
              'Q: AI总结功能无法使用？\nA: 请检查网络连接和AI服务配置，确保API密钥正确。',
              'Q: 如何设置白名单？\nA: 进入设置 > 白名单管理，添加信任的发件人或关键词。',
              'Q: 邮件无法同步？\nA: 检查邮箱配置和网络连接，确保邮箱服务正常。',
            ],
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '联系我们',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('如果您遇到问题或有建议，欢迎联系我们：'),
                  const SizedBox(height: 8),
                  const Text('• 邮箱：support@newsreader.com'),
                  const Text('• 版本：v0.2.1'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )),
          ],
        ),
      ),
    );
  }
}