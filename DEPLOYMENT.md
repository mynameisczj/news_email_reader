# 项目部署指南

## 环境要求

### 系统要求
- Windows 10/11 或 macOS 或 Linux
- 至少 4GB RAM
- 至少 10GB 可用磁盘空间

### 开发环境
- Flutter SDK 3.0.0 或更高版本
- Dart SDK 3.0.0 或更高版本
- Android Studio 或 VS Code
- Git

## 安装步骤

### 1. 安装Flutter
```bash
# Windows (使用Git Bash或PowerShell)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 验证安装
flutter doctor
```

### 2. 配置开发环境
```bash
# 接受Android许可证
flutter doctor --android-licenses

# 启用Web和桌面支持
flutter config --enable-web
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### 3. 克隆项目
```bash
git clone <repository-url>
cd news_email_reader
```

### 4. 安装依赖
```bash
flutter pub get
```

## 运行项目

### Android设备/模拟器
```bash
# 连接Android设备或启动模拟器
flutter devices

# 运行应用
flutter run
```

### Web浏览器
```bash
flutter run -d chrome
# 或
flutter run -d edge
```

### Windows桌面
```bash
flutter run -d windows
```

### 构建发布版本
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web版本
flutter build web --release

# Windows桌面
flutter build windows --release
```

## 网络问题解决方案

如果遇到网络连接问题，可以尝试以下解决方案：

### 1. 配置代理
```bash
# 设置HTTP代理
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080

# 或在Flutter配置中设置
flutter config --proxy-host proxy.company.com --proxy-port 8080
```

### 2. 使用镜像源
```bash
# 中国大陆用户可以使用清华镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### 3. 离线安装
如果网络问题持续存在，可以：
1. 在有网络的环境中下载Flutter SDK
2. 手动下载所需的依赖包
3. 使用离线安装方式

## 常见问题

### Q: 运行时出现"找不到设备"错误
A: 确保已连接Android设备或启动了模拟器，运行`flutter devices`检查可用设备。

### Q: 依赖包安装失败
A: 尝试清理缓存后重新安装：
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Q: 编译错误
A: 检查Flutter和Dart版本是否符合要求：
```bash
flutter --version
dart --version
```

## 项目结构说明

```
news_email_reader/
├── android/                 # Android平台配置
├── lib/                     # Dart源代码
│   ├── main.dart           # 应用入口
│   ├── core/               # 核心模块
│   └── features/           # 功能模块
├── assets/                 # 资源文件
├── test/                   # 测试文件
└── pubspec.yaml           # 项目配置
```

## 开发建议

1. 使用VS Code或Android Studio进行开发
2. 安装Flutter和Dart插件
3. 启用热重载功能提高开发效率
4. 定期运行`flutter doctor`检查环境状态
5. 使用`flutter analyze`检查代码质量

## 技术支持

如果遇到问题，可以：
1. 查看Flutter官方文档：https://flutter.dev/docs
2. 搜索Flutter社区：https://flutter.dev/community
3. 提交Issue到项目仓库