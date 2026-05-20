#!/bin/bash
# 讯聊 Android APK 打包脚本（仅 arm64，输出带版本号）
set -e

cd "$(dirname "$0")"

echo ">>> 正在打包 Android APK（arm64，混淆+剥离符号，仅新系统 minSdk 30）..."

flutter clean
flutter pub get

# ================== ⭐ 读取版本号 ==================
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)

echo ">>> 当前版本号: $VERSION"

# ================== 打包 ==================
flutter build apk \
  --target-platform android-arm64 \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

echo ""

APK_DIR="build/app/outputs/flutter-apk"

# ================== ⭐ 输出文件名带版本号 ==================
OUTPUT_NAME="/Users/ma/data/apk/xchat_v${VERSION}.apk"

# 复制并重命名
if [ -f "$APK_DIR/app-release.apk" ]; then
  cp "$APK_DIR/app-release.apk" "$OUTPUT_NAME"
  echo "✅ 已复制到: $OUTPUT_NAME"
else
  echo "❌ APK 未找到"
fi

echo ""
echo "安装包目录: $(pwd)/$APK_DIR/"