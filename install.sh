#!/usr/bin/env bash
set -e

# ===== 可改参数（一般不用动）=====
SOCKS_PORT=12324
VLESS_PORT=23456

# ===== 自动生成 =====
SOCKS_USER=$(openssl rand -hex 6)
SOCKS_PASS=$(openssl rand -hex 5)
UUID=$(cat /proc/sys/kernel/random/uuid)

echo "[1/6] Installing dependencies..."
apt update -y >/dev/null 2>&1
apt install -y curl unzip openssl iproute2 >/dev/null 2>&1

echo "[2/6] Installing Xray..."
mkdir -p /usr/local/bin
cd /usr/local/bin
curl -sL -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -oq xray.zip
chmod +x xray

echo "[3/6] Writing config..."
cat >/etc/xray.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${SOCKS_PORT},
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          { "user": "${SOCKS_USER}", "pass": "${SOCKS_PASS}" }
        ],
        "udp": true
      }
    },
    {
      "listen": "0.0.0.0",
      "port": ${VLESS_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "${UUID}" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

echo "[4/6] Testing config..."
/usr/local/bin/xray run -test -config /etc/xray.json

echo "[5/6] Creating service..."
cat >/etc/systemd/system/xray-sv.service <<EOF
[Unit]
Description=Xray SOCKS5 + VLESS
After=network.target

[Service]
ExecStart=/usr/local/bin/xray run -config /etc/xray.json
Restart=always
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray-sv
systemctl restart xray-sv

sleep 2

IP=$(curl -s https://ifconfig.me || curl -s https://ipinfo.io/ip)

echo
echo "================= RESULT ================="
echo
echo "SOCKS5 URL:"
echo "socks5://${SOCKS_USER}:${SOCKS_PASS}@${IP}:${SOCKS_PORT}"
echo
echo "SOCKS5 :"
echo "${IP}:${SOCKS_PORT}:${SOCKS_USER}:${SOCKS_PASS}"
echo
echo "VLESS:"
echo "vless://${UUID}@${IP}:${VLESS_PORT}?type=tcp&security=none"
echo
echo "=========================================="
