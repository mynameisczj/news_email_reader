import 'package:enough_mail/enough_mail.dart';
import '../models/email_account.dart';
import '../models/email_message.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final Map<int, MailClient> _clients = {};

  /// 连接邮件服务器
  Future<bool> connectAccount(EmailAccount account) async {
    try {
      final client = MailClient(
        account: MailAccount.fromManualSettings(
          name: account.displayName ?? account.email,
          email: account.email,
          incoming: MailServerConfig(
            serverConfig: ServerConfig(
              hostname: account.serverHost,
              port: account.serverPort,
              socketType: account.useSsl ? SocketType.ssl : SocketType.plain,
            ),
            authentication: PlainAuthentication(account.email, account.password),
            serverCapabilities: [Capability.idle],
          ),
          outgoing: MailServerConfig(
            serverConfig: ServerConfig(
              hostname: account.serverHost,
              port: account.protocol == 'SMTP' ? 587 : 993,
              socketType: account.useSsl ? SocketType.ssl : SocketType.plain,
            ),
            authentication: PlainAuthentication(account.email, account.password),
          ),
        ),
      );

      await client.connect();
      _clients[account.id!] = client;
      return true;
    } catch (e) {
      print('连接邮件服务器失败: $e');
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnectAccount(int accountId) async {
    final client = _clients[accountId];
    if (client != null) {
      await client.disconnect();
      _clients.remove(accountId);
    }
  }

  /// 获取邮件列表
  Future<List<EmailMessage>> fetchEmails(
    EmailAccount account, {
    int count = 50,
    int page = 1,
  }) async {
    final client = _clients[account.id];
    if (client == null) {
      throw Exception('邮件客户端未连接');
    }

    try {
      await client.selectInbox();
      final fetchResult = await client.fetchRecentMessages(
        messageCount: count,
        criteria: 'UNSEEN',
      );

      final emails = <EmailMessage>[];
      for (final message in fetchResult.messages) {
        final email = _convertToEmailMessage(message, account.id!);
        emails.add(email);
      }

      return emails;
    } catch (e) {
      print('获取邮件失败: $e');
      return [];
    }
  }

  /// 获取邮件详细内容
  Future<EmailMessage?> fetchEmailContent(
    EmailAccount account,
    String messageId,
  ) async {
    final client = _clients[account.id];
    if (client == null) {
      throw Exception('邮件客户端未连接');
    }

    try {
      await client.selectInbox();
      final searchResult = await client.searchMessages(
        searchCriteria: SearchQueryBuilder().header('Message-ID', messageId),
      );

      if (searchResult.matchingSequences?.isNotEmpty == true) {
        final sequence = searchResult.matchingSequences!.first;
        final fetchResult = await client.fetchMessage(sequence);
        return _convertToEmailMessage(fetchResult, account.id!);
      }

      return null;
    } catch (e) {
      print('获取邮件内容失败: $e');
      return null;
    }
  }

  /// 标记邮件为已读
  Future<bool> markAsRead(EmailAccount account, String messageId) async {
    final client = _clients[account.id];
    if (client == null) return false;

    try {
      await client.selectInbox();
      final searchResult = await client.searchMessages(
        searchCriteria: SearchQueryBuilder().header('Message-ID', messageId),
      );

      if (searchResult.matchingSequences?.isNotEmpty == true) {
        final sequence = searchResult.matchingSequences!.first;
        await client.markSeen(MessageSequence.fromSequence(sequence));
        return true;
      }

      return false;
    } catch (e) {
      print('标记已读失败: $e');
      return false;
    }
  }

  /// 转换邮件消息格式
  EmailMessage _convertToEmailMessage(MimeMessage message, int accountId) {
    return EmailMessage(
      accountId: accountId,
      messageId: message.getHeaderValue('Message-ID') ?? '',
      subject: message.decodeSubject() ?? '无主题',
      senderName: message.from?.first.personalName,
      senderEmail: message.from?.first.email ?? '',
      recipientEmail: message.to?.first.email,
      contentText: message.decodeTextPlainPart(),
      contentHtml: message.decodeTextHtmlPart(),
      receivedDate: message.decodeDate() ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  /// 测试邮件服务器连接
  Future<bool> testConnection(EmailAccount account) async {
    try {
      final client = MailClient(
        account: MailAccount.fromManualSettings(
          name: account.displayName ?? account.email,
          email: account.email,
          incoming: MailServerConfig(
            serverConfig: ServerConfig(
              hostname: account.serverHost,
              port: account.serverPort,
              socketType: account.useSsl ? SocketType.ssl : SocketType.plain,
            ),
            authentication: PlainAuthentication(account.email, account.password),
          ),
          outgoing: MailServerConfig(
            serverConfig: ServerConfig(
              hostname: account.serverHost,
              port: account.protocol == 'SMTP' ? 587 : 993,
              socketType: account.useSsl ? SocketType.ssl : SocketType.plain,
            ),
            authentication: PlainAuthentication(account.email, account.password),
          ),
        ),
      );

      await client.connect();
      await client.disconnect();
      return true;
    } catch (e) {
      print('测试连接失败: $e');
      return false;
    }
  }

  /// 断开所有连接
  Future<void> disconnectAll() async {
    for (final client in _clients.values) {
      await client.disconnect();
    }
    _clients.clear();
  }
}