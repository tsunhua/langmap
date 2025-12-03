#!/bin/bash

# build.sh - 构建脚本，将前端构建后放置到后端static目录

set -e  # 遇到错误时退出

echo "开始构建LangMap应用程序..."

# 创建后端static目录（如果不存在）
STATIC_DIR="backend/app/static"
echo "确保静态目录存在: $STATIC_DIR"
mkdir -p "$STATIC_DIR"

# 清理之前的构建
echo "清理之前的构建..."
rm -rf "$STATIC_DIR"/*

# 进入web目录并安装依赖（如果需要）
if [ ! -d "web/node_modules" ]; then
    echo "安装前端依赖..."
    cd web
    npm install
    cd ..
fi

# 构建前端应用
echo "构建前端应用..."
cd web
npm run build
cd ..

# 复制构建结果到后端static目录
echo "复制构建文件到后端static目录..."
cp -r web/dist/* "$STATIC_DIR"/

# 确认文件复制成功
if [ -d "$STATIC_DIR" ] && [ "$(ls -A $STATIC_DIR)" ]; then
    echo "构建成功完成！"
    echo "静态文件已复制到: $STATIC_DIR"
    echo "文件列表:"
    ls -la "$STATIC_DIR"
else
    echo "错误：构建文件复制失败"
    exit 1
fi

echo "现在可以运行后端服务来提供完整的应用程序"