#! /bin/bash
# 此脚本用于安装hysteria2服务

# 内核配置
tcpConf=/etc/sysctl.conf
# 配置文件
conf=/etc/hysteria/config.yaml
# 设置
function setOrReplaceConf() {
  key="$1"
  value="$2"
  exist=$(cat $tcpConf | grep $key=)
  if [ -z "$exist" ]; then
    echo "$key=$value" >>$tcpConf
  else
    sed -i "s/$key=.*/$key=$value/g" $tcpConf
  fi
}

# 创建用户
username=hysteria
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
curl -fsSL https://get.hy2.sh/ | bash

# 设置系统缓冲区大小，将发送、接收两个缓冲区都设置为 16 MB
setOrReplaceConf "net.core.rmem_max" "16777216"
setOrReplaceConf "net.core.wmem_max" "16777216"
echo "内核信息："
sysctl -p

# 修改配置文件
if [ -f "$conf" ]; then
  quic=$(cat $conf | grep "quic")
  if [ -z "$quic" ]; then
    # 优化配置，QUIC 流控制接收窗口参数
    echo "
quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864
" >>$conf
  fi
fi

# 替换组用户
sed -i "s/Group=.*/Group=certusers/g" /etc/systemd/system/hysteria-server.service
rm -f /etc/systemd/system/hysteria-server@.service

echo "systemctl start hysteria-server运行后会在/home/hysteria中生成证书"

