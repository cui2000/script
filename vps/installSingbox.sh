#! /bin/bash
# 此脚本用于安装sing-box服务

# 创建用户
username=sing-box
groupname=certusers
# 判断用户是否存在
if id -u "$username" >/dev/null 2>&1; then
  echo "使用用户$username"
else
  # 创建不能登录的系统用户，不建立同名用户组，不建立文件夹
  echo "创建用户$username"
  useradd -Nmrs /sbin/nologin $username
fi

# 判断组是否存在
if getent group "$groupname" >/dev/null 2>&1; then
  echo "使用用户组$groupname"
else
  echo "创建用户组$groupname"
  groupadd -r $groupname
fi
usermod -aG "$groupname" "$username"

# 安装
rootPath=/home/soft
mkdir -p $rootPath
arch=$(uname -m)
version="1.11.0-beta.24"
# 不是AMD
if [ "$arch" = "x86_64" ]; then
  flag=amd64
elif [ "$arch" = "aarch64" ]; then
  flag=arm64
else
  echo "只支持amd和arm"
  exit 0
fi

# 下载
wget -P $rootPath https://github.com/SagerNet/sing-box/releases/download/v$version/sing-box-$version-linux-$flag.tar.gz
# 解压
tar -xzf $rootPath/sing-box-$version-linux-$flag.tar.gz -C $rootPath
# 删除压缩包
rm -f $rootPath/sing-box-$version-linux-$flag.tar.gz
# 创建配置文件（hysteria2相关配置）
appPath=$rootPath/sing-box-$version-linux-$flag
echo '{
  "log": {
    "level": "info",
    "output": "box.log",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "cloudflare",
        "address": "https://1.1.1.1/dns-query",
        "detour": "direct"
      },
      {
        "tag": "block",
        "address": "rcode://success"
      }
    ],
    "rules": [
      {
        "rule_set": "geosite-category-ads-all",
        "server": "block",
        "disable_cache": true
      }
    ],
    "final": "cloudflare",
    "strategy": "prefer_ipv6",
    "disable_cache": false,
    "disable_expire": false
  },
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": 443,
      "tcp_fast_open": true,
      "tcp_multi_path": true,
      "udp_fragment": true,
      "udp_timeout": 300,
      "up_mbps": 100,
      "down_mbps": 100,
      "users": [
        {
          "name": "修改为自己的用户名，没有则留空",
          "password": "修改为自己的密码"
        }
      ],
      "ignore_client_bandwidth": false,
      "tls": {
        "enabled": true,
        "certificate_path": "修改为自己的证书路径",
        "key_path": "修改为自己的证书路径",
        "alpn": [
          "h3"
        ]
      },
      "masquerade": "修改为要伪装的网址，比如https://github.com",
      "brutal_debug": false
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "action": "hijack-dns"
      },
      {
        "rule_set": "geosite-category-ads-all",
        "action": "reject"
      },
      {
        "inbound": "hy2-in",
        "action": "resolve",
        "strategy": "prefer_ipv6"
      },
      {
        "inbound": "hy2-in",
        "action": "sniff",
        "timeout": "300ms"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "auto_detect_interface": true,
    "final": "direct"
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    },
    "clash_api": {
      "external_controller": "0.0.0.0:9190",
      "external_ui": "metacubexd",
      "external_ui_download_url": "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip",
      "external_ui_download_detour": "direct",
      "default_mode": "rule"
    }
  }
}' >$appPath/config.json
# 授权
chown -R $username:$groupname $appPath

# 安装为服务
echo "安装sing-box为服务"
echo "[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target network-online.target

[Service]
User=sing-box
Group=certusers
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
WorkingDirectory=$appPath
ExecStart=$appPath/sing-box run
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/sing-box.service

#刷新
systemctl daemon-reload

echo "应用目录为：$appPath，请修改config.json后启动"
echo "开机自启：systemctl enable sing-box.service"
echo "启动服务：systemctl start sing-box.service"
echo "如果要开启端口转发，请执行以下命令：
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --permanent --zone=public --add-forward-port=port=ip起-ip终:proto=udp:toport=443
sudo firewall-cmd --reload
查看：sudo firewall-cmd --list-all
或者
编辑/etc/sysctl.conf文件，设置net.ipv4.ip_forward = 1
sudo sysctl -p
sudo iptables -t nat -A PREROUTING -p udp --dport 20000:30000 -j REDIRECT --to-port 443
sudo iptables -A FORWARD -p udp --dport 443 -j ACCEPT
sudo iptables-save | sudo tee /etc/sysconfig/iptables
查看：
sudo iptables -t nat -L -n -v
sudo iptables -L -n -v"
