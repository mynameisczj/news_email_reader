import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_message.dart';
import '../../../../core/services/ai_service.dart';

import '../../../../core/repositories/email_repository.dart';
import '../../../notes/presentation/pages/note_editor_page.dart';

class EmailReaderPage extends ConsumerStatefulWidget {
  final EmailMessage email;

  const EmailReaderPage({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailReaderPage> createState() => _EmailReaderPageState();
}

class _EmailReaderPageState extends ConsumerState<EmailReaderPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isStarred = false;
  bool _isGeneratingSummary = false;
  String? _aiSummary;
  double _fontSize = 16.0;
  final EmailRepository _emailRepository = EmailRepository();

  @override
  void initState() {
    super.initState();
    _isStarred = widget.email.isStarred;
    _aiSummary = widget.email.aiSummary;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isStarred ? Icons.star : Icons.star_border,
            color: _isStarred ? AppTheme.secondaryColor : AppTheme.textSecondaryColor,
          ),
          onPressed: _toggleStar,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareEmail,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreMenuBottomSheet,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmailHeader(),
          const SizedBox(height: 24),
          if (_aiSummary != null) _buildAISummary(),
          _buildEmailBody(),
          const SizedBox(height: 100), // 底部工具栏空间
        ],
      ),
    );
  }

  Widget _buildEmailHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.email.subject,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _fontSize + 4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    widget.email.displaySender[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.email.displaySender,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.email.senderEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(widget.email.receivedDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      _formatTime(widget.email.receivedDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISummary() {
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 总结',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiSummary!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: _fontSize,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailBody() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.email.contentHtml != null)
              Html(
                data: widget.email.contentHtml!,
                style: {
                  "body": Style(
                    fontSize: FontSize(_fontSize),
                    lineHeight: const LineHeight(1.6),
                    color: AppTheme.textPrimaryColor,
                    backgroundColor: Colors.transparent,
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 12),
                  ),
                  "a": Style(
                    color: AppTheme.primaryColor,
                    textDecoration: TextDecoration.underline,
                  ),
                  "img": Style(
                    width: Width(double.infinity),
                    height: Height.auto(),
                  ),
                },
                onLinkTap: (url, _, __) {
                  if (url != null) {
                    _launchUrl(url);
                  }
                },
              )
            else if (widget.email.contentText != null)
              Text(
                widget.email.contentText!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: _fontSize,
                  height: 1.6,
                ),
              )
            else
              Text(
                '无邮件内容',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            icon: Icons.auto_awesome,
            label: 'AI总结',
            onPressed: _generateAISummary,
            isLoading: _isGeneratingSummary,
          ),
          _buildToolbarButton(
            icon: Icons.translate,
            label: '翻译',
            onPressed: _translateEmail,
          ),
          _buildToolbarButton(
            icon: Icons.note_add,
            label: '笔记',
            onPressed: _addNote,
          ),
          _buildToolbarButton(
            icon: Icons.text_fields,
            label: '字体',
            onPressed: _showFontSizeDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              )
            else
              Icon(
                icon,
                color: AppTheme.textPrimaryColor,
                size: 24,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStar() async {
    try {
      final newStarredState = !_isStarred;
      final updatedEmail = widget.email.copyWith(isStarred: newStarredState);
      
      // 同时更新repository和mock service
      // 同时更新repository和mock service
      // 持久化到仓库（基于messageId保存）
      await _emailRepository.updateEmail(updatedEmail);


      
      setState(() {
        _isStarred = newStarredState;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStarredState ? '已添加到收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新收藏状态失败: $e')),
        );
      }
    }
  }

  void _shareEmail() {
    final content = '''
${widget.email.subject}

发件人: ${widget.email.displaySender}
时间: ${_formatDate(widget.email.receivedDate)} ${_formatTime(widget.email.receivedDate)}

${widget.email.contentText ?? ''}
''';
    Share.share(content);
  }

  void _showMoreMenuBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('翻译'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleMenuAction('translate');
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: const Text('笔记'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleMenuAction('note');
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('字体大小'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleMenuAction('font_size');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'translate':
        _translateEmail();
        break;
      case 'note':
        _addNote();
        break;
      case 'font_size':
        _showFontSizeDialog();
        break;
    }
  }

  Future<void> _generateAISummary() async {
    if (_isGeneratingSummary) return;

    if (!mounted) return;
    
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      final aiService = AIService();
      final content = widget.email.contentText ?? widget.email.contentHtml ?? '';
      final summary = await aiService.generateSummary(
        widget.email.subject,
        content,
      );

      // 保存总结到本地存储（以messageId为键）
      final updatedEmail = widget.email.copyWith(aiSummary: summary);
      await _emailRepository.updateEmail(updatedEmail);

      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isGeneratingSummary = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI总结已生成并保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成总结失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _translateEmail() {
    // TODO: 实现翻译功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('翻译功能开发中...')),
    );
  }

  void _addNote() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(email: widget.email),
      ),
    );
    
    // 如果笔记有更新，刷新邮件数据
    if (result == true) {
      try {
        // 重新获取更新后的邮件数据
        final updatedEmail = await _emailRepository.getEmailContent(widget.email.messageId);
        if (updatedEmail != null && mounted) {
          // 这里可以更新widget.email的引用，但由于widget.email是final的，
          // 我们只显示成功消息，实际的笔记内容会在下次进入时正确显示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('笔记已保存'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('刷新邮件数据失败: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字体大小'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前大小: ${_fontSize.toInt()}'),
              Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) {
                  setDialogState(() {
                    _fontSize = value;
                  });
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(date.year, date.month, date.day);

    if (emailDate == today) {
      return '今天';
    } else if (emailDate == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
