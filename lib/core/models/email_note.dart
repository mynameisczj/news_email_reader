class EmailNote {
  final int? id;
  final int emailId;
  final String title;
  final String content;
  final String? tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailNote({
    this.id,
    required this.emailId,
    required this.title,
    required this.content,
    this.tags,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email_id': emailId,
      'title': title,
      'content': content,
      'tags': tags,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EmailNote.fromMap(Map<String, dynamic> map) {
    return EmailNote(
      id: map['id'],
      emailId: map['email_id'],
      title: map['title'],
      content: map['content'],
      tags: map['tags'],
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  EmailNote copyWith({
    int? id,
    int? emailId,
    String? title,
    String? content,
    String? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailNote(
      id: id ?? this.id,
      emailId: emailId ?? this.emailId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取标签列表
  List<String> getTagList() {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  /// 设置标签列表
  EmailNote setTagList(List<String> tagList) {
    final tagsString = tagList.where((tag) => tag.trim().isNotEmpty).join(', ');
    return copyWith(tags: tagsString.isEmpty ? null : tagsString);
  }

  /// 添加标签
  EmailNote addTag(String tag) {
    final currentTags = getTagList();
    if (!currentTags.contains(tag.trim())) {
      currentTags.add(tag.trim());
      return setTagList(currentTags);
    }
    return this;
  }

  /// 移除标签
  EmailNote removeTag(String tag) {
    final currentTags = getTagList();
    currentTags.remove(tag.trim());
    return setTagList(currentTags);
  }

  /// 检查是否包含标签
  bool hasTag(String tag) {
    return getTagList().contains(tag.trim());
  }

  @override
  String toString() {
    return 'EmailNote{id: $id, emailId: $emailId, title: $title, content: $content, tags: $tags, isFavorite: $isFavorite, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailNote &&
        other.id == id &&
        other.emailId == emailId &&
        other.title == title &&
        other.content == content &&
        other.tags == tags &&
        other.isFavorite == isFavorite &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        emailId.hashCode ^
        title.hashCode ^
        content.hashCode ^
        tags.hashCode ^
        isFavorite.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}