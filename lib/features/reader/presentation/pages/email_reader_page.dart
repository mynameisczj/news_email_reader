import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/email_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/repositories/email_repository.dart';
import '../../../../core/services/ai_service.dart';

class EmailReaderPage extends StatefulWidget {
  final EmailMessage email;

  const EmailReaderPage({super.key, required this.email});

  @override
  State<EmailReaderPage> createState() => _EmailReaderPageState();
}

class _EmailReaderPageState extends State<EmailReaderPage> {
  // For Android/iOS
  late final WebViewController _webViewController;

  // For Windows
  final _windowsController = windows_webview.WebviewController();

  bool _isWebViewLoading = true;
  late EmailMessage _currentEmail;
  final EmailRepository _emailRepository = EmailRepository();

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (Platform.isWindows) {
      await _windowsController.initialize();
      await _windowsController.loadStringContent(
        _currentEmail.contentHtml ?? _currentEmail.contentText ?? '邮件内容为空',
      );
      _windowsController.url.listen((url) async {
        if (url.startsWith('http')) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      });
    } else {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isWebViewLoading = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) async {
              if (request.url.startsWith('http')) {
                final uri = Uri.parse(request.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(
          _currentEmail.contentHtml ?? _currentEmail.contentText ?? '邮件内容为空',
        );
    }

    if (mounted) {
      setState(() {
        _isWebViewLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _currentEmail.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showEmailOptions(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isWebViewLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasContent = (_currentEmail.contentHtml?.trim().isNotEmpty ?? false) ||
                       (_currentEmail.contentText?.trim().isNotEmpty ?? false);

    if (!hasContent) {
      return const Center(
        child: Text('邮件内容为空', style: TextStyle(color: Colors.grey)),
      );
    }

    if (Platform.isWindows) {
      return windows_webview.Webview(
        _windowsController,
        permissionRequested: (url, permission, isUserInitiated) async {
          return windows_webview.WebviewPermissionDecision.allow;
        },
      );
    } else {
      return WebViewWidget(controller: _webViewController);
    }
  }

  void _showEmailOptions() {
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
            ListTile(
              leading: Icon(_currentEmail.isStarred ? Icons.star_border : Icons.star),
              title: Text(_currentEmail.isStarred ? '取消收藏' : '收藏'),
              onTap: () {
                Navigator.pop(context);
                _toggleStar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI总结'),
              onTap: () {
                Navigator.pop(context);
                _generateAISummary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('翻译'),
              onTap: () {
                Navigator.pop(context);
                _translateEmail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                _shareEmail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteEmail();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStar() async {
    try {
      await _emailRepository.updateEmailStatus(
        _currentEmail.messageId,
        isStarred: !_currentEmail.isStarred,
      );
      _refreshEmailState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!_currentEmail.isStarred ? '已收藏邮件' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _showErrorSnack('操作失败: $e');
    }
  }

  void _generateAISummary() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成AI总结...')),
    );

    try {
      final aiService = AIService();
      final content = _currentEmail.contentText ?? _currentEmail.contentHtml ?? '';
      final summary = await aiService.generateSummary(_currentEmail.subject, content);
      await _emailRepository.updateEmailStatus(_currentEmail.messageId, aiSummary: summary);
      _refreshEmailState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI总结已生成')),
        );
      }
    } catch (e) {
      _showErrorSnack('生成总结失败: $e');
    }
  }

  void _translateEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('翻译功能开发中...')),
    );
  }

  void _shareEmail() {
    Share.share(
        '主题: ${_currentEmail.subject}\\n发件人: ${_currentEmail.senderEmail}\\n\\n${_currentEmail.contentText ?? ''}');
  }

  Future<void> _deleteEmail() async {
    try {
      await _emailRepository.deleteEmail(_currentEmail.messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除邮件: ${_currentEmail.subject}'),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      _showErrorSnack('删除失败: $e');
    }
  }

  Future<void> _refreshEmailState() async {
    final updatedEmail = await _emailRepository.getEmailContent(_currentEmail.messageId);
    if (updatedEmail != null && mounted) {
      setState(() {
        _currentEmail = updatedEmail;
      });
    }
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}