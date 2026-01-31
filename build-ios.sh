#!/bin/bash

# build-ios.sh - iOS 应用构建脚本

set -e  # 遇到错误时退出

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_PATH="$SCRIPT_DIR/apple/langmap.xcodeproj"
SCHEME_NAME="langmap"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max}"

echo "=========================================="
echo "  LangMap iOS 应用构建脚本"
echo "=========================================="
echo ""
echo "配置信息:"
echo "  项目路径: $PROJECT_PATH"
echo "  Scheme: $SCHEME_NAME"
echo "  配置: $CONFIGURATION"
echo "  SDK: $SDK"
echo "  目标设备: $DESTINATION"
echo ""

# 检查 Xcode 项目是否存在
if [ ! -f "$PROJECT_PATH/project.pbxproj" ]; then
    echo "错误: 找不到 Xcode 项目文件: $PROJECT_PATH"
    exit 1
fi

# 清理 DerivedData
echo "清理 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/langmap-*

# 构建项目
echo ""
echo "开始构建 iOS 应用..."
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -sdk "$SDK" \
    -destination "$DESTINATION" \
    clean build

# 检查构建结果
BUILD_RESULT=$?
echo ""

if [ $BUILD_RESULT -eq 0 ]; then
    echo "=========================================="
    echo "  构建成功！"
    echo "=========================================="
    echo ""
    echo "应用已成功构建，可以在 Xcode 中运行或安装到模拟器上。"
    echo ""
    echo "查看构建产物:"
    echo "  ~/Library/Developer/Xcode/DerivedData/langmap-*/Build/Products/$CONFIGURATION-$SDK/"
else
    echo "=========================================="
    echo "  构建失败！"
    echo "=========================================="
    echo ""
    echo "请检查上面的错误信息并修复问题。"
    exit 1
fi
