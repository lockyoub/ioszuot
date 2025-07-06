#!/bin/bash

# iOS应用构建脚本
# 作者: MiniMax Agent
# 用途: GitHub Actions中自动化构建iOS应用

set -e  # 遇到错误立即退出

echo "🚀 开始iOS应用构建过程..."

# 配置变量
PROJECT_NAME="StockTradingApp"
SCHEME="StockTradingApp-Package"
CONFIGURATION="Release"
BUILD_DIR="./build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/ipa"

# 清理之前的构建
echo "🧹 清理之前的构建文件..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 显示环境信息
echo "📋 构建环境信息:"
echo "Xcode版本: $(xcodebuild -version | head -1)"
echo "Swift版本: $(swift --version | head -1)"
echo "可用SDK: $(xcodebuild -showsdks | grep iphoneos | tail -1)"

# 解析Swift包依赖
echo "📦 解析Swift包依赖..."
swift package resolve

# 生成Xcode项目
echo "🏗️  生成Xcode项目..."
swift package generate-xcodeproj

# 检查项目和scheme
echo "🔍 检查项目配置..."
if [ ! -f "$PROJECT_NAME.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误: Xcode项目文件未找到"
    exit 1
fi

echo "可用的schemes:"
xcodebuild -list -project "$PROJECT_NAME.xcodeproj"

# 执行Archive构建
echo "🔨 开始Archive构建..."
xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty || true

# 检查Archive是否成功
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive构建失败"
    exit 1
fi

echo "✅ Archive构建成功: $ARCHIVE_PATH"

# 导出IPA
echo "📱 导出IPA文件..."
mkdir -p "$EXPORT_PATH"

# 尝试标准导出
if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates 2>/dev/null; then
    
    echo "✅ 标准IPA导出成功"
    
else
    echo "⚠️  标准导出失败，尝试手动创建未签名IPA..."
    
    # 手动创建IPA
    APP_PATH="$ARCHIVE_PATH/Products/Applications/$PROJECT_NAME.app"
    if [ -d "$APP_PATH" ]; then
        # 创建Payload目录结构
        mkdir -p "$EXPORT_PATH/Payload"
        cp -r "$APP_PATH" "$EXPORT_PATH/Payload/"
        
        # 创建IPA文件
        cd "$EXPORT_PATH"
        zip -r "../$PROJECT_NAME-unsigned.ipa" Payload/
        cd - > /dev/null
        
        echo "✅ 未签名IPA创建成功: $BUILD_DIR/$PROJECT_NAME-unsigned.ipa"
    else
        echo "❌ 错误: 在Archive中未找到App文件"
        exit 1
    fi
fi

# 显示构建结果
echo ""
echo "🎉 构建完成！"
echo "📁 构建产物:"
find "$BUILD_DIR" -name "*.ipa" -exec echo "  - {}" \;

echo ""
echo "📋 构建摘要:"
echo "  项目: $PROJECT_NAME"
echo "  配置: $CONFIGURATION"
echo "  时间: $(date)"
echo "  状态: 成功 ✅"

exit 0
