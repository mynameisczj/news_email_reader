// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_message.dart';
import '../../../../core/repositories/email_repository.dart';
import '../../../reader/presentation/pages/email_reader_page.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  List<EmailMessage> _favoriteEmails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteEmails();
  }

  Future<void> _loadFavoriteEmails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final emailRepository = ref.read(emailRepositoryProvider);
      final emails = await emailRepository.getStarredEmails();
      setState(() {
        _favoriteEmails = emails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载收藏邮件失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(EmailMessage email) async {
    try {
      final emailRepository = ref.read(emailRepositoryProvider);
      final updatedEmail = email.copyWith(isStarred: !email.isStarred);
      await emailRepository.updateEmail(updatedEmail);
      
      setState(() {
        if (updatedEmail.isStarred) {
          _favoriteEmails.add(updatedEmail);
        } else {
          _favoriteEmails.removeWhere((e) => e.id == email.id);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新收藏状态失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏邮件'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteEmails.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          SizedBox(height: 16),
          Text(
            '暂无收藏邮件',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '点击邮件右上角的星标来收藏邮件',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: _loadFavoriteEmails,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteEmails.length,
        itemBuilder: (context, index) {
          final email = _favoriteEmails[index];
          return _buildEmailCard(email);
        },
      ),
    );
  }

  Widget _buildEmailCard(EmailMessage email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailReaderPage(email: email),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      email.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      email.isStarred ? Icons.star : Icons.star_border,
                      color: email.isStarred ? Colors.amber : AppTheme.textSecondaryColor,
                    ),
                    onPressed: () => _toggleFavorite(email),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                email.displaySender,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email.previewContent,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(email.receivedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (email.aiSummary != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AI总结',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}