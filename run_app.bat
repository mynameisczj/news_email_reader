@echo off
echo 启动极客新闻邮件阅读APP...
echo.

echo 检查Flutter环境...
flutter doctor --android-licenses

echo.
echo 获取依赖包...
flutter pub get

echo.
echo 启动应用...
flutter run

pause