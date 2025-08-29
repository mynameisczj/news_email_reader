import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/email_message.dart';
import '../../../../core/repositories/email_repository.dart';
import '../../../../core/services/storage_service.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final EmailMessage email;

  const NoteEditorPage({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late TextEditingController _notesController;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesController.addListener(_onTextChanged);
    _loadExistingNote();
  }

  Future<void> _loadExistingNote() async {
    try {
      // 从StorageService加载最新的邮件数据
      final storageService = StorageService.instance;
      final emails = await storageService.getAllEmails();
      final currentEmail = emails.firstWhere(
        (e) => e.messageId == widget.email.messageId,
        orElse: () => widget.email,
      );
      
      final noteText = currentEmail.notes ?? '';
      setState(() {
        _notesController.text = noteText;
      });
    } catch (e) {
      // 如果加载失败，使用传入的email中的笔记
      setState(() {
        _notesController.text = widget.email.notes ?? '';
      });
    }
  }

  @override
  void dispose() {
    _notesController.removeListener(_onTextChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _notesController.text != (widget.email.notes ?? '');
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _saveNotes() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final emailRepository = ref.read(emailRepositoryProvider);
      final updatedEmail = widget.email.copyWith(
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      await emailRepository.updateEmail(updatedEmail);
      
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('笔记已保存'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 返回true表示有更新
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的笔记更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('离开'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _saveNotes();
            },
            child: const Text('保存并离开'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑笔记'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isSaving ? null : _saveNotes,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '保存',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildEmailInfo(),
            Expanded(
              child: _buildNoteEditor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '邮件主题',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.email.subject,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '发件人: ${widget.email.displaySender}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '我的笔记',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '未保存',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '在这里记录您的想法、总结或重要信息...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '笔记会自动关联到这封邮件，您可以在笔记页面查看所有笔记',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}