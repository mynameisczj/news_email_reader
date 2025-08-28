import '../database/database_helper.dart';
import '../models/email_note.dart';

class NoteService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 添加笔记
  Future<int> addNote(EmailNote note) async {
    final database = await _db.database;
    return await database.insert('email_notes', note.toMap());
  }

  /// 更新笔记
  Future<int> updateNote(EmailNote note) async {
    final database = await _db.database;
    return await database.update(
      'email_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// 删除笔记
  Future<int> deleteNote(int noteId) async {
    final database = await _db.database;
    return await database.delete(
      'email_notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  /// 根据邮件ID获取笔记
  Future<List<EmailNote>> getNotesByEmailId(int emailId) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      where: 'email_id = ?',
      whereArgs: [emailId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EmailNote.fromMap(map)).toList();
  }

  /// 根据笔记ID获取笔记
  Future<EmailNote?> getNoteById(int noteId) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return EmailNote.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有笔记
  Future<List<EmailNote>> getAllNotes() async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EmailNote.fromMap(map)).toList();
  }

  /// 搜索笔记
  Future<List<EmailNote>> searchNotes(String keyword) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      where: 'content LIKE ? OR title LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EmailNote.fromMap(map)).toList();
  }

  /// 根据标签获取笔记
  Future<List<EmailNote>> getNotesByTag(String tag) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EmailNote.fromMap(map)).toList();
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      columns: ['tags'],
      where: 'tags IS NOT NULL AND tags != ""',
    );
    
    final tagSet = <String>{};
    for (final map in maps) {
      final tagsString = map['tags'] as String?;
      if (tagsString != null && tagsString.isNotEmpty) {
        final tags = tagsString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty);
        tagSet.addAll(tags);
      }
    }
    
    final tagList = tagSet.toList();
    tagList.sort();
    return tagList;
  }

  /// 获取笔记统计信息
  Future<Map<String, int>> getNoteStats() async {
    final database = await _db.database;
    
    // 总笔记数
    final totalResult = await database.rawQuery('SELECT COUNT(*) as count FROM email_notes');
    final totalNotes = totalResult.first['count'] as int;
    
    // 今日笔记数
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayResult = await database.rawQuery(
      'SELECT COUNT(*) as count FROM email_notes WHERE created_at >= ?',
      [todayStart.toIso8601String()],
    );
    final todayNotes = todayResult.first['count'] as int;
    
    // 本周笔记数
    final weekStart = todayStart.subtract(Duration(days: today.weekday - 1));
    final weekResult = await database.rawQuery(
      'SELECT COUNT(*) as count FROM email_notes WHERE created_at >= ?',
      [weekStart.toIso8601String()],
    );
    final weekNotes = weekResult.first['count'] as int;
    
    // 本月笔记数
    final monthStart = DateTime(today.year, today.month, 1);
    final monthResult = await database.rawQuery(
      'SELECT COUNT(*) as count FROM email_notes WHERE created_at >= ?',
      [monthStart.toIso8601String()],
    );
    final monthNotes = monthResult.first['count'] as int;
    
    return {
      'total': totalNotes,
      'today': todayNotes,
      'week': weekNotes,
      'month': monthNotes,
    };
  }

  /// 导出笔记
  Future<List<Map<String, dynamic>>> exportNotes() async {
    final notes = await getAllNotes();
    return notes.map((note) => note.toMap()).toList();
  }

  /// 导入笔记
  Future<void> importNotes(List<Map<String, dynamic>> notesData) async {
    final database = await _db.database;
    
    for (final noteData in notesData) {
      try {
        final note = EmailNote.fromMap(noteData);
        await database.insert('email_notes', note.toMap());
      } catch (e) {
        // 忽略导入失败的笔记
        continue;
      }
    }
  }

  /// 清空所有笔记
  Future<void> clearAllNotes() async {
    final database = await _db.database;
    await database.delete('email_notes');
  }

  /// 删除指定邮件的所有笔记
  Future<int> deleteNotesByEmailId(int emailId) async {
    final database = await _db.database;
    return await database.delete(
      'email_notes',
      where: 'email_id = ?',
      whereArgs: [emailId],
    );
  }

  /// 批量删除笔记
  Future<int> deleteNotesByIds(List<int> noteIds) async {
    if (noteIds.isEmpty) return 0;
    
    final database = await _db.database;
    final placeholders = List.filled(noteIds.length, '?').join(',');
    return await database.delete(
      'email_notes',
      where: 'id IN ($placeholders)',
      whereArgs: noteIds,
    );
  }

  /// 复制笔记
  Future<int> duplicateNote(int noteId) async {
    final originalNote = await getNoteById(noteId);
    if (originalNote == null) {
      throw Exception('笔记不存在');
    }
    
    final duplicatedNote = EmailNote(
      emailId: originalNote.emailId,
      title: '${originalNote.title} (副本)',
      content: originalNote.content,
      tags: originalNote.tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return await addNote(duplicatedNote);
  }

  /// 获取最近的笔记
  Future<List<EmailNote>> getRecentNotes({int limit = 10}) async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return maps.map((map) => EmailNote.fromMap(map)).toList();
  }

  /// 获取收藏的笔记
  Future<List<EmailNote>> getFavoriteNotes() async {
    final database = await _db.database;
    final maps = await database.query(
      'email_notes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => EmailNote.fromMap(map)).toList();
  }

  /// 切换笔记收藏状态
  Future<void> toggleNoteFavorite(int noteId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      final updatedNote = EmailNote(
        id: note.id,
        emailId: note.emailId,
        title: note.title,
        content: note.content,
        tags: note.tags,
        isFavorite: !note.isFavorite,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
      );
      await updateNote(updatedNote);
    }
  }
}