import 'dart:async';
import '../models/email_message.dart';

/// 模拟邮件服务，用于演示和测试
class MockEmailService {
  static final MockEmailService _instance = MockEmailService._internal();
  factory MockEmailService() => _instance;
  MockEmailService._internal();

  // 模拟邮件数据
  final List<EmailMessage> _mockEmails = [
    EmailMessage(
      accountId: 1,
      messageId: 'msg_001',
      subject: '科技日报 - AI技术突破性进展',
      senderName: '科技日报',
      senderEmail: 'tech@example.com',
      contentText: '本期内容包括：OpenAI发布最新模型、谷歌AI突破性进展、苹果智能功能更新...',
      contentHtml: '<p>本期内容包括：OpenAI发布最新模型、谷歌AI突破性进展、苹果智能功能更新...</p>',
      receivedDate: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      isStarred: true,
      aiSummary: '这是一篇关于AI技术的新闻邮件，包含了最新的行业动态和技术进展。',
      createdAt: DateTime.now(),
    ),
    EmailMessage(
      accountId: 1,
      messageId: 'msg_002',
      subject: '极客周刊 - 开源项目推荐',
      senderName: '极客周刊',
      senderEmail: 'geek@example.com',
      contentText: '本周推荐的开源项目包括：Flutter新组件库、Rust性能优化工具...',
      contentHtml: '<p>本周推荐的开源项目包括：Flutter新组件库、Rust性能优化工具...</p>',
      receivedDate: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      isStarred: false,
      createdAt: DateTime.now(),
    ),
    EmailMessage(
      accountId: 1,
      messageId: 'msg_003',
      subject: '程序员日报 - 编程语言趋势分析',
      senderName: '程序员日报',
      senderEmail: 'dev@example.com',
      contentText: '2024年编程语言使用趋势：Python持续增长，Rust备受关注...',
      contentHtml: '<p>2024年编程语言使用趋势：Python持续增长，Rust备受关注...</p>',
      receivedDate: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: false,
      isStarred: false,
      createdAt: DateTime.now(),
    ),
  ];

  /// 获取邮件列表
  Future<List<EmailMessage>> getEmails({
    int limit = 20,
    int offset = 0,
    String? filter,
  }) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    var emails = List<EmailMessage>.from(_mockEmails);
    
    // 应用筛选
    if (filter != null) {
      switch (filter) {
        case '今日':
          emails = emails.where((email) => 
            email.receivedDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))
          ).toList();
          break;
        case '本周':
          emails = emails.where((email) => 
            email.receivedDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))
          ).toList();
          break;
        case '已总结':
          emails = emails.where((email) => email.aiSummary != null).toList();
          break;
        case '已收藏':
          emails = emails.where((email) => email.isStarred).toList();
          break;
      }
    }
    
    // 分页
    final start = offset;
    final end = (start + limit).clamp(0, emails.length);
    
    return emails.sublist(start, end);
  }

  /// 标记邮件为已读/未读
  Future<void> markAsRead(String messageId, bool isRead) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final index = _mockEmails.indexWhere((email) => email.messageId == messageId);
    if (index != -1) {
      _mockEmails[index] = _mockEmails[index].copyWith(isRead: isRead);
    }
  }

  /// 收藏/取消收藏邮件
  Future<void> toggleStar(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final index = _mockEmails.indexWhere((email) => email.messageId == messageId);
    if (index != -1) {
      _mockEmails[index] = _mockEmails[index].copyWith(
        isStarred: !_mockEmails[index].isStarred,
      );
    }
  }

  /// 删除邮件
  Future<void> deleteEmail(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _mockEmails.removeWhere((email) => email.messageId == messageId);
  }

  /// 生成AI总结
  Future<String> generateAISummary(String messageId) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final index = _mockEmails.indexWhere((email) => email.messageId == messageId);
    if (index != -1) {
      final summary = '这是一篇关于${_mockEmails[index].subject}的邮件总结，包含了主要内容和关键信息。';
      _mockEmails[index] = _mockEmails[index].copyWith(aiSummary: summary);
      return summary;
    }
    
    throw Exception('邮件未找到');
  }

  /// 翻译邮件内容
  Future<String> translateEmail(String messageId, String targetLanguage) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final index = _mockEmails.indexWhere((email) => email.messageId == messageId);
    if (index != -1) {
      return '${_mockEmails[index].contentText} (已翻译为$targetLanguage)';
    }
    
    throw Exception('邮件未找到');
  }

  /// 刷新邮件
  Future<List<EmailMessage>> refreshEmails() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // 模拟添加新邮件
    final newEmail = EmailMessage(
      accountId: 1,
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      subject: '新邮件 - ${DateTime.now().hour}:${DateTime.now().minute}',
      senderName: '测试发件人',
      senderEmail: 'test@example.com',
      contentText: '这是一封新的测试邮件内容...',
      contentHtml: '<p>这是一封新的测试邮件内容...</p>',
      receivedDate: DateTime.now(),
      isRead: false,
      isStarred: false,
      createdAt: DateTime.now(),
    );
    
    _mockEmails.insert(0, newEmail);
    return _mockEmails;
  }
}