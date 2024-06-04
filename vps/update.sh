#! /bin/bash
# 此脚本用于更新系统并安装必备应用

function enableSSSD() {
  # 如果没有配置文件
  if [ -f "/etc/sssd/sssd.conf" ]; then
    echo "[sssd]
services = nss, pam
domains = shadowutils

[nss]

[pam]

[domain/shadowutils]
id_provider = proxy
proxy_lib_name = files

auth_provider = proxy
proxy_pam_target = sssd-shadowutils

proxy_fast_alias = True" >/etc/sssd/sssd.conf
    chmod 600 /etc/sssd/sssd.conf
  fi
  systemctl enable sssd.service
  systemctl start sssd
}

function update() {
  isCentOS=$(cat /etc/*-release | grep CentOS)
  isDebian=$(cat /etc/*-release | grep Debian)
  if [ ! -z "$isCentOS" ]; then
    yum clean all
    yum -y update
    yum -y install vim wget curl pcre pcre-devel zlib zlib-devel gcc gcc-c++ openssl openssl-devel automake autoconf libtool make sssd net-tools socat cronie unzip fuse
    # sssd服务
    enableSSSD
    # 定时任务服务
    systemctl start crond
    systemctl enable crond
  elif [ ! -z "$isDebian" ]; then
    # 升级
    apt -y upgrade
    # 安装必要软件包
    apt -y install vim wget curl libpcre3 libpcre3-dev zlib1g zlib1g-dev gcc g++ build-essential openssl libssl-dev automake autoconf libtool make sssd net-tools socat unzip fuse
    # 卸载不需要的软件包
    apt -y autoremove
  else
    echo "暂时只支持CentOS和Debian"
    exit 0
  fi

}

# 脚本目录及配置文件
script_path=/home/soft/script
script_file="$script_path/config.sh"
if [ ! -f "$script_file" ]; then
  mkdir -p $script_path
  url_path="https://raw.githubusercontent.com/cui2000/script/dev/vps/config.sh"
  curl -o "$script_file" "$url_path"
  # 检查下载是否成功
  if [ $? -eq 0 ]; then
    # 执行下载的脚本
    bash "$script_file"
  else
    echo "Failed to download script from $urlPath"
  fi
fi

isUpdate=$(sh "$script_file" "get" "isUpdate")
if [ "$isUpdate" != "1" ]; then
  update
  sh "$script_file" "set" "isUpdate" "1"
fi
