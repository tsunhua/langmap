#!/bin/bash

# build.sh - 構建腳本，將 v2 前端構建後放置到 v2 後端 public 目錄

set -e

echo "開始構建 LangMap v2 應用程式..."

STATIC_DIR="backend_v2/public"
echo "確保靜態目錄存在: $STATIC_DIR"
mkdir -p "$STATIC_DIR"

echo "清理之前的構建..."
rm -rf "$STATIC_DIR"/*

if [ ! -d "web_v2/node_modules" ]; then
    echo "安裝前端依賴..."
    cd web_v2
    npm install
    cd ..
fi

echo "構建前端應用..."
cd web_v2
npm run build
cd ..

echo "複製構建檔案到後端 public 目錄..."
cp -r web_v2/dist/* "$STATIC_DIR"/

if [ -d "$STATIC_DIR" ] && [ "$(ls -A $STATIC_DIR)" ]; then
    echo "構建成功完成！"
    echo "靜態檔案已複製到: $STATIC_DIR"
    ls -la "$STATIC_DIR"
else
    echo "錯誤：構建檔案複製失敗"
    exit 1
fi
