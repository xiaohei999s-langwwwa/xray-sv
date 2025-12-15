#!/bin/bash
set -e

echo "=============================="
echo " STEP 1: 确保基础依赖"
echo "=============================="
apt update -y
apt install -y curl unzip jq

echo
echo "=============================="
echo " STEP 2: 安装 Xray Core（独立）"
echo "=============================="

if ! command -v xray >/dev/null 2>&1; then
    curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
    unzip -o /tmp/xray.zip -d /usr/local/bin
    chmod +x /usr/local/bin/xray
else
    echo "[INFO] Xray 已存在"
fi

echo
echo "=============================="
echo " STEP 3: 执行你的自定义安装脚本"
echo "=============================="

TMP_DIR=/tmp/xray-custom-install
rm -rf $TMP_DIR
mkdir -p $TMP_DIR
cd $TMP_DIR

curl -fsSL https://raw.githubusercontent.com/xiaohei999s-langwwwa/xray-sv/main/install.sh -o install.sh
chmod +x install.sh
bash install.sh

echo
echo "=============================="
echo " ✅ 完成：Xray + SOCKS + VLESS"
echo "=============================="
