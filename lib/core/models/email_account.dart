class EmailAccount {
  final int? id;
  final String email;
  final String password;
  final String protocol; // IMAP, POP3, SMTP, Exchange
  final String serverHost;
  final int serverPort;
  final bool useSsl;
  final String? displayName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailAccount({
    this.id,
    required this.email,
    required this.password,
    required this.protocol,
    required this.serverHost,
    required this.serverPort,
    this.useSsl = true,
    this.displayName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'protocol': protocol,
      'server_host': serverHost,
      'server_port': serverPort,
      'use_ssl': useSsl ? 1 : 0,
      'display_name': displayName,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EmailAccount.fromMap(Map<String, dynamic> map) {
    return EmailAccount(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      protocol: map['protocol'],
      serverHost: map['server_host'],
      serverPort: map['server_port'],
      useSsl: map['use_ssl'] == 1,
      displayName: map['display_name'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  EmailAccount copyWith({
    int? id,
    String? email,
    String? password,
    String? protocol,
    String? serverHost,
    int? serverPort,
    bool? useSsl,
    String? displayName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      protocol: protocol ?? this.protocol,
      serverHost: serverHost ?? this.serverHost,
      serverPort: serverPort ?? this.serverPort,
      useSsl: useSsl ?? this.useSsl,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}