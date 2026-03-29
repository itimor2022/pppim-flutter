#!/bin/bash
# 讯聊 Android APK 打包脚本（仅 arm64，输出名为 讯聊.apk）
set -e
cd "$(dirname "$0")"
echo ">>> 正在打包 Android APK（arm64，混淆+剥离符号，仅新系统 minSdk 30）..."
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --obfuscate --split-debug-info=build/app/outputs/symbols
echo ""
APK_DIR="build/app/outputs/flutter-apk"
DESKTOP="$HOME"
OUTPUT_NAME="data/apk/享聊.apk"
# 只打 arm64，产物为 app-release.apk，复制到桌面并重命名为 讯聊.apk
[ -f "$APK_DIR/app-release.apk" ] && cp "$APK_DIR/app-release.apk" "$DESKTOP/$OUTPUT_NAME" && echo "已复制到桌面: $OUTPUT_NAME"
echo ""
echo "安装包在: $(pwd)/$APK_DIR/"
echo "桌面文件: $DESKTOP/$OUTPUT_NAME"
