#! /bin/bash
# 此脚本用于安装sing-box服务

# sing-box启动标识
isStart=1

# 是否启动
function checkStarted(){
  isStart=$(ps aux | grep sing-box | grep -v grep)
}

# 启动
function startSingBox(){
  echo "启动sing-box..."
  systemctl enable --now sing-box
  sleep 1
  checkStarted
  if [ -z "$isStart" ]; then
    echo "启动sing-box失败"
  else
    echo "启动sing-box成功"
  fi
}


# 创建用户
function createUser() {
  username="$1"
  groupname="$2"

  # 如果没有输入组名，默认同用户名
  if [ -z "$groupname" ]; then
    groupname="$username"
  fi

  # 判断用户是否存在
  if id -u "$username" >/dev/null 2>&1; then
    echo "使用用户$username"
  else
    # 创建不能登录的系统用户，不建立同名用户组，不建立文件夹
    echo "创建用户$username"
    useradd -NMrs /sbin/nologin $username
  fi

  # 判断组是否存在
  if getent group "$groupname" >/dev/null 2>&1; then
    echo "使用用户组$groupname"
  else
    echo "创建用户组$groupname"
    groupadd -r $groupname
  fi

  # 添加用户到用户组
  usermod -aG $groupname $username
}

function installSingBox() {
  # 检测系统架构
  arch=$(uname -m)
  if [ "$arch" = "x86_64" ]; then
    flag=amd64
  elif [ "$arch" = "aarch64" ]; then
    flag=arm64
  else
    echo "只支持amd和arm"
    exit 0
  fi

  # 创建用户
  username="sing-box"
  groupname="certusers"
  createUser $username $groupname

  # 下载
  version="1.12.0-rc.2"
  appPath=/home/soft/sing-box
  wget -P $appPath https://github.com/SagerNet/sing-box/releases/download/v$version/sing-box-$version-linux-$flag.tar.gz
  # 解压
  tar --strip-components=1 -xzf $appPath/sing-box-$version-linux-$flag.tar.gz -C $appPath
  # 删除压缩包
  rm -f $appPath/sing-box-$version-linux-$flag.tar.gz

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
          "type": "https",
          "server": "1.1.1.1"
        }
      ],
      "strategy": "prefer_ipv4",
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
        "udp_fragment": false,
        "udp_timeout": "300s",
        "up_mbps": 50,
        "down_mbps": 50,
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
        "masquerade": {
          "type": "proxy",
          "url": "修改为要伪装的网址，比如https://github.com",
          "rewrite_host": true
        },
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
        }
      ]
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
        "default_mode": "rule",
        "secret": "修改为自己的密码"
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
  User=$username
  Group=$groupname
  CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
  AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
  WorkingDirectory=$appPath
  ExecStart=$appPath/sing-box run
  Restart=on-failure
  RestartSec=10s
  LimitNOFILE=infinity

  [Install]
  WantedBy=multi-user.target" >/etc/systemd/system/sing-box.service

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
  sudo iptables -t nat -A PREROUTING -p udp --dport ip起:ip终 -j REDIRECT --to-port 443
  sudo iptables -A FORWARD -p udp --dport 443 -j ACCEPT
  sudo iptables-save | sudo tee /etc/sysconfig/iptables
  查看：
  sudo iptables -t nat -L -n -v
  sudo iptables -L -n -v"
  echo "ui界面需要开放9190端口，请访问http://ip:9190/ui/#/setup"
}

hasSingBox=$(systemctl list-unit-files | grep sing-box)
if [ -z "$hasSingBox" ]; then
  echo "sing-box未安装"
  installSingBox
else
  echo "sing-box已安装"
  # 判断是否启动
  checkStarted
  if [ -z "$isStart" ]; then
    startSingBox
  else
    echo "sing-box已启动"
    ps aux | grep sing-box
  fi
fi