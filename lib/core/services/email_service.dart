import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:logging/logging.dart';
import '../models/email_message.dart';
import '../models/email_account.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal() {
    // 禁用enough_mail库的详细日志输出
    if (kDebugMode) {
      Logger('enough_mail').level = Level.WARNING;
      Logger('imap').level = Level.WARNING;
      Logger('pop3').level = Level.WARNING;
      Logger('smtp').level = Level.WARNING;
    }
  }

  // 连接测试：尝试登录对应协议，成功即返回 true
  Future<bool> connectToAccount(EmailAccount account) async {
    final protocol = account.protocol.toUpperCase();
    try {
      if (protocol == 'IMAP') {
        final client = ImapClient(isLogEnabled: false);
        await client.connectToServer(account.serverHost, account.serverPort, isSecure: account.useSsl);
        await client.login(account.email, account.password);
        await client.logout();
        await client.disconnect();
        return true;
      } else if (protocol == 'POP3') {
        final client = PopClient(isLogEnabled: false);
        await client.connectToServer(account.serverHost, account.serverPort, isSecure: account.useSsl);
        await client.login(account.email, account.password);
        await client.quit();
        await client.disconnect();
        return true;
      } else {
        // 仅 IMAP/POP3 用于读取
        return false;
      }
    } on MailException catch (e) {
      // 授权失败/网络错误
      // ignore: avoid_print
      debugPrint('connectToAccount failed: $e');
      return false;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('connectToAccount error: $e');
      return false;
    }
  }

  // 对外保留空实现，实际每次抓取走短连接
  Future<void> disconnect() async {}

  // 抓取最近邮件（使用账户协议），解析主题/发件人/时间与文本/HTML内容
  Future<List<EmailMessage>> fetchRecentEmails(
    EmailAccount account, {
    int? count,
  }) async {
    final protocol = account.protocol.toUpperCase();
    // 默认获取更多邮件，确保能覆盖被清理的邮件
    final fetchCount = count ?? 2000;
    
    if (protocol == 'IMAP') {
      return _fetchImapRecent(account, count: fetchCount);
    } else if (protocol == 'POP3') {
      return _fetchPop3Recent(account, count: fetchCount);
    } else {
      throw UnsupportedError('仅支持 IMAP/POP3 读取邮件');
    }
  }

  // 使用 enough_mail 的便捷方法获取最近邮件
  Future<List<EmailMessage>> _fetchImapRecent(EmailAccount account, {int count = 1000}) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(account.serverHost, account.serverPort, isSecure: account.useSsl);
      await client.login(account.email, account.password);
      await client.selectInbox();

      // 使用便捷方法抓取最近邮件（返回 FetchImapResult，其中包含 messages）
      final fetch = await client.fetchRecentMessages(messageCount: count);
      final List<MimeMessage> messages = fetch.messages;

      final List<EmailMessage> result = [];
      for (final mime in messages) {
        try {
          result.add(_mimeToEmailMessage(
            mime,
            account,
            messageIdFallback: 'imap_${DateTime.now().millisecondsSinceEpoch}',
          ));
        } catch (e) {
          // 单封失败不影响整体
          // ignore: avoid_print
          debugPrint('imap convert message error: $e');
        }
      }
      return result;
    } on MailException catch (e) {
      // ignore: avoid_print
      debugPrint('IMAP fetch error: $e');
      rethrow;
    } finally {
      try {
        if (client.isLoggedIn) {
          await client.logout();
        }
      } catch (_) {}
      try {
        await client.disconnect();
      } catch (_) {}
    }
  }

  Future<List<EmailMessage>> _fetchPop3Recent(EmailAccount account, {int count = 1000}) async {
    final client = PopClient(isLogEnabled: false);
    try {
      await client.connectToServer(account.serverHost, account.serverPort, isSecure: account.useSsl);
      await client.login(account.email, account.password);

      // 获取服务器邮件总数，POP3 按索引 1..N
      final status = await client.status();
      final total = status?.numberOfMessages ?? 0;
      if (total == 0) {
        return <EmailMessage>[];
      }

      final fetchCount = total < count ? total : count;
      final List<EmailMessage> result = [];
      for (int i = total; i > total - fetchCount; i--) {
        try {
          final mime = await client.retrieve(i);
          if (mime != null) {
            // POP3 无 UID，构造一个确定性的 fallback
            result.add(_mimeToEmailMessage(
              mime,
              account,
              messageIdFallback: 'pop3_${account.email}_$i',
            ));
          }
        } catch (e) {
          // ignore: avoid_print
          debugPrint('POP3 retrieve index=$i error: $e');
        }
      }
      return result;
    } on MailException catch (e) {
      // ignore: avoid_print
      debugPrint('POP3 fetch error: $e');
      rethrow;
    } finally {
      try {
        await client.quit();
      } catch (_) {}
      try {
        await client.disconnect();
      } catch (_) {}
    }
  }

  EmailMessage _mimeToEmailMessage(
    MimeMessage mime,
    EmailAccount account, {
    required String messageIdFallback,
  }) {
    final subject = mime.decodeSubject() ?? '(无主题)';
    final from = mime.from?.isNotEmpty == true ? mime.from!.first : null;
    final senderName = from?.personalName;
    final senderEmail = from?.email ?? 'unknown@unknown';
    final date = mime.decodeDate() ?? DateTime.now();

    String? text;
    String? html;

    try {
      // 优先获取纯文本部分
      text = mime.decodeTextPlainPart();
      // 总是获取HTML部分，如果存在的话
      html = mime.decodeTextHtmlPart();

      // 如果两者都为空，则设置一个占位符
      if ((text == null || text.trim().isEmpty) && (html == null || html.trim().isEmpty)) {
        text = '(无内容)';
      }
    } catch (e) {
      debugPrint('邮件内容解析失败: $e');
      text = '(邮件内容解析失败)';
      html = null;
    }

    // 优先使用邮件头中的 Message-ID，如果不存在，则生成一个确定性的 ID
    final String messageId = mime.getHeaderValue('Message-ID') ?? _deterministicMessageId(
      account.email,
      senderEmail,
      date,
      subject,
      messageIdFallback,
    );

    return EmailMessage(
      accountId: account.id ?? 0,
      messageId: messageId,
      subject: subject,
      senderName: senderName,
      senderEmail: senderEmail,
      recipientEmail: account.email,
      contentText: text,
      contentHtml: html,
      receivedDate: date,
      isRead: false,
      isStarred: false,
      createdAt: DateTime.now(),
    );
  }

  String _deterministicMessageId(
    String accountEmail,
    String senderEmail,
    DateTime date,
    String subject,
    String seed,
  ) {
    // 将时间戳舍入到分钟级别，以避免微秒差异
    final roundedDate = DateTime(date.year, date.month, date.day, date.hour, date.minute);
    final subjectHash = _stableHash(subject);
    final seedHash = _stableHash(seed.toString());
    final base = 'msg_${accountEmail}_${senderEmail}_${roundedDate.millisecondsSinceEpoch}_${subjectHash}_${seedHash}';
    return base.replaceAll(RegExp(r'[^A-Za-z0-9_\\-@.]'), '_');
  }

  int _stableHash(String s) {
    var h = 0;
    for (final cu in s.codeUnits) {
      h = (h * 31 + cu) & 0x7fffffff;
    }
    return h;
  }
}