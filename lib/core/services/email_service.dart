import 'dart:async';
import '../models/email_message.dart';
import '../models/email_account.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  bool _isConnected = false;
  EmailAccount? _currentAccount;

  Future<bool> connectToAccount(EmailAccount account) async {
    try {
      // 模拟连接过程
      await Future.delayed(const Duration(seconds: 1));
      
      _currentAccount = account;
      _isConnected = true;
      print('Successfully connected to email account: ${account.email}');
      return true;
    } catch (e) {
      print('Failed to connect to email account: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _isConnected = false;
        _currentAccount = null;
        print('Disconnected from email account');
      } catch (e) {
        print('Error disconnecting: $e');
      }
    }
  }

  Future<List<EmailMessage>> fetchRecentEmails({int count = 50}) async {
    if (!_isConnected || _currentAccount == null) {
      throw Exception('Not connected to email account');
    }

    try {
      // 模拟获取邮件
      await Future.delayed(const Duration(seconds: 2));
      
      return _generateMockEmails(count);
    } catch (e) {
      print('Error fetching recent emails: $e');
      return [];
    }
  }

  Future<List<EmailMessage>> searchEmails({
    String? fromEmail,
    String? subject,
    DateTime? since,
    DateTime? before,
  }) async {
    if (!_isConnected || _currentAccount == null) {
      throw Exception('Not connected to email account');
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟搜索结果
      final allEmails = _generateMockEmails(20);
      return allEmails.where((email) {
        if (fromEmail != null && !email.senderEmail.contains(fromEmail)) {
          return false;
        }
        if (subject != null && !email.subject.toLowerCase().contains(subject.toLowerCase())) {
          return false;
        }
        if (since != null && email.receivedDate.isBefore(since)) {
          return false;
        }
        if (before != null && email.receivedDate.isAfter(before)) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      print('Error searching emails: $e');
      return [];
    }
  }

  Future<List<EmailMessage>> fetchEmailsByKeywords(List<String> keywords) async {
    if (!_isConnected || _currentAccount == null) {
      throw Exception('Not connected to email account');
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final allEmails = _generateMockEmails(30);
      return allEmails.where((email) {
        final content = '${email.subject} ${email.previewContent}'.toLowerCase();
        return keywords.any((keyword) => content.contains(keyword.toLowerCase()));
      }).toList();
    } catch (e) {
      print('Error fetching emails by keywords: $e');
      return [];
    }
  }

  Future<bool> connectToPop3Account(EmailAccount account) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _currentAccount = account;
      _isConnected = true;
      print('Successfully connected to POP3 account: ${account.email}');
      return true;
    } catch (e) {
      print('Failed to connect to POP3 account: $e');
      _isConnected = false;
      return false;
    }
  }

  List<EmailMessage> _generateMockEmails(int count) {
    final emails = <EmailMessage>[];
    final senders = [
      'GitHub <noreply@github.com>',
      'Stack Overflow <noreply@stackoverflow.com>',
      'Medium <noreply@medium.com>',
      'Dev.to <noreply@dev.to>',
      'Hacker News <noreply@hackernews.com>',
      'TechCrunch <newsletter@techcrunch.com>',
      'Ars Technica <newsletter@arstechnica.com>',
      'The Verge <newsletter@theverge.com>',
    ];

    final subjects = [
      '[GitHub] New release available for flutter/flutter',
      'Weekly digest: Top questions this week',
      'New story published: Understanding Flutter State Management',
      'DEV Community Digest: This week\'s top posts',
      'Ask HN: What are you working on?',
      'Breaking: Apple announces new MacBook Pro',
      'Review: The latest in quantum computing research',
      'This Week in Tech: AI developments',
    ];

    final contents = [
      'A new version of Flutter has been released with improved performance and new features...',
      'Here are the most popular questions from this week on Stack Overflow...',
      'In this comprehensive guide, we explore the different state management solutions...',
      'Check out these amazing posts from the DEV community this week...',
      'Share what you\'re currently working on and get feedback from the community...',
      'Apple has just announced their latest MacBook Pro with the new M3 chip...',
      'Researchers have made significant breakthroughs in quantum computing...',
      'This week has been exciting for AI development with several major announcements...',
    ];

    for (int i = 0; i < count; i++) {
      final senderInfo = senders[i % senders.length];
      final senderParts = senderInfo.split(' <');
      final senderName = senderParts[0];
      final senderEmail = senderParts[1].replaceAll('>', '');

      emails.add(EmailMessage(
        accountId: 1,
        messageId: 'mock_${i + 1}',
        subject: subjects[i % subjects.length],
        senderEmail: senderEmail,
        senderName: senderName,
        recipientEmail: _currentAccount?.email ?? 'user@example.com',
        contentText: contents[i % contents.length],
        contentHtml: '<p>${contents[i % contents.length]}</p>',
        receivedDate: DateTime.now().subtract(Duration(hours: i)),
        isRead: i % 3 == 0,
        isStarred: i % 5 == 0,
        createdAt: DateTime.now().subtract(Duration(hours: i)),
      ));
    }

    return emails;
  }

  bool get isConnected => _isConnected;
  EmailAccount? get currentAccount => _currentAccount;
}