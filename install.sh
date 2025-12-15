#!/bin/bash
set -e

# ===== 随机参数 =====
SOCKS_PORT=$(shuf -i 20000-30000 -n 1)
VLESS_PORT=$(shuf -i 30001-40000 -n 1)

USER=$(openssl rand -hex 6)
PASS=$(openssl rand -hex 5)
UUID=$(cat /proc/sys/kernel/random/uuid)

IP=$(curl -s ifconfig.me)

XRAY_BIN=$(command -v xray || command -v v2ray)
CONF_DIR=/etc/xray
CONF_FILE=$CONF_DIR/custom.json

if [ -z "$XRAY_BIN" ]; then
  echo "❌ 未检测到 xray / v2ray core，请先运行 233boy 脚本"
  exit 1
fi

mkdir -p $CONF_DIR

# ===== 写配置 =====
cat > $CONF_FILE <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $SOCKS_PORT,
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          { "user": "$USER", "pass": "$PASS" }
        ],
        "udp": true
      }
    },
    {
      "listen": "0.0.0.0",
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

# ===== 单独 systemd（不影响 233boy）=====
cat >/etc/systemd/system/xray-custom.service <<EOF
[Unit]
Description=Xray Custom Inbounds
After=network.target

[Service]
ExecStart=$XRAY_BIN run -config $CONF_FILE
Restart=always
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray-custom >/dev/null
systemctl restart xray-custom

sleep 1

# ===== 输出结果 =====
echo
echo "================ 生成结果 ================"
echo
echo "SOCKS 四段式："
echo "$IP:$SOCKS_PORT:$USER:$PASS"
echo
echo "SOCKS URL："
echo "socks5://$USER:$PASS@$IP:$SOCKS_PORT"
echo
echo "VLESS："
echo "vless://$UUID@$IP:$VLESS_PORT?type=tcp&security=none"
echo
echo "=========================================="
