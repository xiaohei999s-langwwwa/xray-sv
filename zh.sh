#!/bin/bash
set -e

echo "=============================="
echo " STEP 1: 安装 V2Ray/Xray Core "
echo "=============================="

if ! command -v v2ray >/dev/null 2>&1 && ! command -v xray >/dev/null 2>&1; then
    bash <(curl -fsSL https://git.io/v2ray.sh)
else
    echo "[INFO] 已检测到 v2ray/xray，跳过安装"
fi

echo
echo "=============================="
echo " STEP 2: 安装自定义 SOCKS + VLESS"
echo "=============================="

TMP_DIR=/tmp/xray-custom-install
rm -rf $TMP_DIR
mkdir -p $TMP_DIR
cd $TMP_DIR

curl -fsSL \
  https://raw.githubusercontent.com/xiaohei999s-langwwwa/xray-sv/main/install.sh \
  -o install.sh

chmod +x install.sh
bash install.sh

echo
echo "=============================="
echo " ✅ 安装完成"
echo "=============================="
