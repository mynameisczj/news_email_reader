import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  static DatabaseHelper get instance => _instance;
  
  static Database? _database;
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'news_email_reader.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // 邮件账户表
    await db.execute('''
      CREATE TABLE email_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        protocol TEXT NOT NULL,
        server_host TEXT NOT NULL,
        server_port INTEGER NOT NULL,
        use_ssl INTEGER NOT NULL DEFAULT 1,
        display_name TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // 邮件表
    await db.execute('''
      CREATE TABLE emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        message_id TEXT NOT NULL UNIQUE,
        subject TEXT NOT NULL,
        sender_name TEXT,
        sender_email TEXT NOT NULL,
        recipient_email TEXT,
        content_text TEXT,
        content_html TEXT,
        received_date TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        is_starred INTEGER NOT NULL DEFAULT 0,
        is_cached INTEGER NOT NULL DEFAULT 0,
        ai_summary TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES email_accounts (id) ON DELETE CASCADE
      )
    ''');
    
    // 白名单表
    await db.execute('''
      CREATE TABLE whitelist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK (type IN ('sender', 'keyword')),
        value TEXT NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    
    // 邮件笔记表
    // 邮件笔记表
    await db.execute('''
      CREATE TABLE email_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (email_id) REFERENCES emails (id) ON DELETE CASCADE
      )
    ''');
    
    // 应用配置表
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // 创建索引
    await db.execute('CREATE INDEX idx_emails_account_id ON emails(account_id)');
    await db.execute('CREATE INDEX idx_emails_sender_email ON emails(sender_email)');
    await db.execute('CREATE INDEX idx_emails_received_date ON emails(received_date)');
    await db.execute('CREATE INDEX idx_whitelist_type_value ON whitelist(type, value)');
  }
  
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}