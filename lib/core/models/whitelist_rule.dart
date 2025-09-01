enum WhitelistType { sender, keyword }

class WhitelistRule {
  final int? id;
  final WhitelistType type;
  final String value;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  WhitelistRule({
    this.id,
    required this.type,
    required this.value,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == WhitelistType.sender ? 'sender' : 'keyword',
      'value': value,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WhitelistRule.fromMap(Map<String, dynamic> map) {
    return WhitelistRule(
      id: map['id'],
      type: map['type'] == 'sender' ? WhitelistType.sender : WhitelistType.keyword,
      value: map['value'],
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  WhitelistRule copyWith({
    int? id,
    WhitelistType? type,
    String? value,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WhitelistRule(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 检查邮件是否匹配此规则
  bool matches(String senderEmail, String subject, String content) {
    if (!isActive) return false;
    
    switch (type) {
      case WhitelistType.sender:
        return _matchesSender(senderEmail);
      case WhitelistType.keyword:
        return _matchesKeyword(subject, content);
    }
  }

  bool _matchesSender(String senderEmail) {
    final email = senderEmail.toLowerCase().trim();
    final rule = value.toLowerCase().trim();
    
    if (rule.isEmpty || email.isEmpty) return false;
    
    // 支持完整邮箱匹配和域名匹配
    if (rule.startsWith('@')) {
      // 域名匹配，如 @example.com
      return email.endsWith(rule);
    } else if (rule.contains('@')) {
      // 完整邮箱匹配
      return email == rule;
    } else {
      // 部分匹配（用户名或域名部分）
      return email.contains(rule);
    }
  }

  bool _matchesKeyword(String subject, String content) {
    final keyword = value.toLowerCase().trim();
    if (keyword.isEmpty) return false;
    
    final subjectLower = subject.toLowerCase();
    final contentLower = content.toLowerCase();
    
    // 支持多个关键词（用逗号分隔）
    final keywords = keyword.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty);
    
    for (final kw in keywords) {
      if (subjectLower.contains(kw) || contentLower.contains(kw)) {
        return true;
      }
    }
    
    return false;
  }
}