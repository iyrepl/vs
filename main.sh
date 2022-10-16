#！请添加$uuid环境变量后运行
##caddy
if [ ! -f "caddy" ];then
    curl -L https://github.com/caddyserver/caddy/releases/download/v2.6.2/caddy_2.6.2_linux_amd64.tar.gz -o caddy.tar.gz
    tar -zxvf caddy.tar.gz
    rm -f LICENSE && rm -f README.md && rm -f caddy.tar.gz
    chmod +x caddy
fi

##diffuse
if [ ! -f "/home/runner/${REPL_SLUG}/build/index.html" ];then
    curl -L https://github.com/icidasset/diffuse/releases/download/3.2.0/diffuse-web.tar.gz -o diffuse-web.tar.gz
    tar -zxvf diffuse-web.tar.gz
    rm -f diffuse-web.tar.gz
fi

##sing-box
if [ ! -f "sing-box" ];then
    curl -L https://github.com/SagerNet/sing-box/releases/download/v1.0.5/sing-box-1.0.5-linux-amd64.tar.gz -o sing-box.tar.gz
  tar -zxvf sing-box.tar.gz
    rm -f LICENSE && rm -f sing-box.tar.gz
    chmod +x sing-box
fi


##config
if [ $uuid ];then
    cat > config.json <<EOF
{
    "log": {
      "disabled": true,
      "level": "info"
    },
    "inbounds": [
      {
        "type": "vmess",
        "tag": "vmess-in",
        "listen": "::",
        "listen_port": 23333,
        "tcp_fast_open": true,
        "sniff": true,
        "sniff_override_destination": false,
        "proxy_protocol": false,
        "users": [
          {
            "name": "example",
            "uuid": "$uuid",
            "alterId": 0
          }
        ],
        "transport": {
          "type": "ws",
          "path": "/$uuid",
          "max_early_data": 0,
          "early_data_header_name": "Sec-WebSocket-Protocol"
        }
      }
    ],
    "outbounds": [
      {
        "type": "direct",
        "tag": "direct"
      }
    ]
  }
EOF
fi

if [ ! -f "caddyfile" ];then
    cat > caddyfile <<EOF
:80
root * /home/runner/${REPL_SLUG}/build
file_server browse

header {
    X-Robots-Tag none
    X-Content-Type-Options nosniff
    X-Frame-Options DENY
    Referrer-Policy no-referrer-when-downgrade
}

@websocket_sing-box {
        path /$uuid
        header Connection *Upgrade*
        header Upgrade websocket
    }
reverse_proxy @websocket_sing-box unix//etc/caddy/vless
EOF
fi


./sing-box run &
./caddy run --config /home/runner/${REPL_SLUG}/caddyfile --adapter caddyfile
