class AppConstants {
  // 应用信息
  static const String appName = '极客新闻邮件阅读器';
  static const String appVersion = '1.0.0';
  static const String appDescription = '专为极客用户设计的新闻邮件阅读应用';
  
  // 数据库配置
  static const String databaseName = 'news_email_reader.db';
  static const int databaseVersion = 1;
  
  // 邮件配置
  static const int defaultEmailFetchCount = 50;
  static const int maxEmailCacheSize = 1000;
  static const Duration emailSyncInterval = Duration(minutes: 15);
  
  // UI配置
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  
  // 缓存配置
  static const Duration imageCacheDuration = Duration(days: 7);
  static const int maxImageCacheSize = 100; // MB
  
  // AI配置
  static const int maxSummaryLength = 500;
  static const Duration aiRequestTimeout = Duration(seconds: 30);
  
  // 常用邮件服务器配置
  static const Map<String, Map<String, dynamic>> emailProviders = {
    'gmail.com': {
      'imap': {'host': 'imap.gmail.com', 'port': 993, 'ssl': true},
      'pop3': {'host': 'pop.gmail.com', 'port': 995, 'ssl': true},
      'smtp': {'host': 'smtp.gmail.com', 'port': 587, 'ssl': true},
    },
    'outlook.com': {
      'imap': {'host': 'outlook.office365.com', 'port': 993, 'ssl': true},
      'pop3': {'host': 'outlook.office365.com', 'port': 995, 'ssl': true},
      'smtp': {'host': 'smtp.office365.com', 'port': 587, 'ssl': true},
    },
    '163.com': {
      'imap': {'host': 'imap.163.com', 'port': 993, 'ssl': true},
      'pop3': {'host': 'pop.163.com', 'port': 995, 'ssl': true},
      'smtp': {'host': 'smtp.163.com', 'port': 587, 'ssl': true},
    },
    'qq.com': {
      'imap': {'host': 'imap.qq.com', 'port': 993, 'ssl': true},
      'pop3': {'host': 'pop.qq.com', 'port': 995, 'ssl': true},
      'smtp': {'host': 'smtp.qq.com', 'port': 587, 'ssl': true},
    },
  };
  
  // 白名单预设规则
  static const List<Map<String, String>> defaultWhitelistRules = [
    {'type': 'sender', 'value': 'newsletter@', 'description': '通用新闻邮件'},
    {'type': 'sender', 'value': 'news@', 'description': '新闻邮件'},
    {'type': 'sender', 'value': 'digest@', 'description': '摘要邮件'},
    {'type': 'sender', 'value': 'update@', 'description': '更新通知'},
    {'type': 'keyword', 'value': '新闻', 'description': '新闻关键词'},
    {'type': 'keyword', 'value': '科技', 'description': '科技关键词'},
    {'type': 'keyword', 'value': '技术', 'description': '技术关键词'},
    {'type': 'keyword', 'value': '资讯', 'description': '资讯关键词'},
  ];
  
  // 支持的翻译语言
  static const Map<String, String> supportedLanguages = {
    'zh': '中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'ru': 'Русский',
  };
  
  // AI模型配置
  static const Map<String, Map<String, String>> aiProviders = {
    'openai': {
      'name': 'OpenAI GPT',
      'baseUrl': 'https://api.openai.com/v1',
      'model': 'gpt-3.5-turbo',
    },
    'tencent': {
      'name': '腾讯混元',
      'baseUrl': 'https://hunyuan.tencentcloudapi.com',
      'model': 'hunyuan-lite',
    },
    'custom': {
      'name': '自定义API',
      'baseUrl': '',
      'model': '',
    },
  };
}