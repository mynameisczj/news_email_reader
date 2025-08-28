# 极客新闻邮件阅读APP

一款面向极客用户的安卓新闻邮件阅读应用，专注于从用户邮箱中智能筛选新闻邮件并提供优质阅读体验。

## 功能特性

### 核心功能
- **多协议邮件接入**：支持POP3/IMAP/SMTP/Exchange等主流邮件协议的授权码认证
- **智能邮件筛选**：基于发件人白名单和关键词过滤，自动识别新闻类邮件
- **纯净阅读界面**：专为新闻邮件优化的阅读体验，支持文字、图片、链接渲染
- **AI智能总结**：集成大语言模型，支持单篇和批量邮件总结，用户可自定义API配置

### 增强功能
- **邮件翻译**：支持多语言翻译功能
- **笔记标注**：为邮件添加个人笔记
- **离线缓存**：支持邮件内容离线阅读
- **快捷订阅**：主流新闻平台快捷订阅

## 技术架构

### 开发框架
- **移动端**：Flutter (Dart)
- **UI设计**：Material Design 3.0
- **状态管理**：Provider + Riverpod
- **本地存储**：SQLite + Hive

### 核心依赖
```yaml
dependencies:
  flutter_riverpod: ^2.4.9      # 状态管理
  sqflite: ^2.3.0               # 本地数据库
  enough_mail: ^2.1.5           # 邮件协议支持
  flutter_html: ^3.0.0-beta.2   # HTML内容渲染
  cached_network_image: ^3.3.0  # 图片缓存
  dio: ^5.4.0                   # 网络请求
```

## 项目结构

```
lib/
├── main.dart                  # 应用入口
├── core/                      # 核心模块
│   ├── theme/                 # 主题配置
│   ├── database/              # 数据库配置
│   ├── models/                # 数据模型
│   ├── services/              # 业务服务
│   └── repositories/          # 数据仓库
└── features/                  # 功能模块
    ├── home/                  # 主页面
    ├── reader/                # 阅读页面
    └── settings/              # 设置页面
```

## 数据库设计

### 主要数据表
- **email_accounts**: 邮件账户信息
- **emails**: 邮件内容数据
- **whitelist**: 白名单规则
- **email_notes**: 邮件笔记
- **app_settings**: 应用配置

## 安装运行

### 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code

### 安装步骤
1. 克隆项目
```bash
git clone <repository-url>
cd news_email_reader
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 使用说明

### 1. 添加邮件账户
- 进入设置页面
- 点击"添加账户"
- 输入邮箱地址和授权码
- 选择邮件协议（IMAP/POP3）
- 配置服务器信息

### 2. 配置白名单
- 添加信任的发件人邮箱
- 设置关键词过滤规则
- 启用/禁用特定规则

### 3. AI总结配置
- 选择AI服务提供商
- 输入API密钥
- 测试连接状态

## 开发进度

- [x] 项目架构搭建
- [x] 数据库模型设计
- [x] 邮件协议服务
- [x] 白名单筛选逻辑
- [x] 主页面UI界面
- [ ] 邮件阅读页面
- [ ] 设置页面
- [ ] AI总结功能
- [ ] 离线缓存机制
- [ ] 翻译笔记功能

## 贡献指南

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

MIT License