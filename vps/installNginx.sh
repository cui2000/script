#! /bin/bash
# 此脚本用于安装nginx服务

# nginx启动标识
isStart=1

# 是否启动
function checkStarted(){
  isStart=$(ps aux | grep nginx | grep -v grep)
}

# 启动
function startNginx(){
  echo "启动nginx..."
  systemctl enable --now nginx
  sleep 1
  checkStarted
  if [ -z "$isStart" ]; then
    echo "启动nginx失败"
  else
    echo "启动nginx成功"
    echo "nginx需要开放80端口，请访问http://ip"
  fi
}

# 先更新系统
function updateSystem() {
  echo "安装必要软件"
  isCentOS=$(cat /etc/*-release | grep CentOS)
  isAlmaLinux=$(cat /etc/*-release | grep AlmaLinux)
  isDebian=$(cat /etc/*-release | grep Debian)
  if [ ! -z "$isCentOS" ] || [ ! -z "$isAlmaLinux" ]; then
    yum -y update
    yum -y install vim wget curl pcre pcre-devel zlib zlib-devel gcc gcc-c++ openssl openssl-devel automake autoconf libtool make sssd net-tools socat cronie unzip fuse
  elif [ ! -z "$isDebian" ]; then
    # 升级
    apt -y upgrade
    # 安装必要软件包
    apt -y install vim wget curl libpcre3 libpcre3-dev zlib1g zlib1g-dev gcc g++ build-essential openssl libssl-dev automake autoconf libtool make sssd net-tools socat unzip fuse
  fi
}

# 安装nginx
function installNginx() {
  # 更新系统，安装必要软件
  updateSystem

  # 版本
  version=1.28.0

  # 设置根目录
  rootPath=/home/soft/nginx

  # 下载
  echo "下载目录：$rootPath"
  wget -P $rootPath http://nginx.org/download/nginx-$version.tar.gz

  # 安装
  cd $rootPath
  tar -xzf nginx-$version.tar.gz
  cd $rootPath/nginx-$version
  ./configure --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-stream
  make
  make install

  echo "安装nginx为服务"
  echo "[Unit]
  Description=nginx service
  After=network.target

  [Service]
  Type=forking
  ExecStart=/usr/local/nginx/sbin/nginx
  ExecStop=/usr/local/nginx/sbin/nginx -s stop
  PrivateTmp=true

  [Install]
  WantedBy=multi-user.target" >/etc/systemd/system/nginx.service

  # 设置系统变量
  echo "export PATH=$PATH:/usr/local/nginx/sbin" >>/etc/profile
  source /etc/profile

  # 输出信息
  echo "nginx下载在$rootPath"
  echo "nginx服务文件是/etc/systemd/system/nginx.service"

  # 启动
  systemctl daemon-reload
  startNginx
}

hasNginx=$(systemctl list-unit-files | grep nginx)
if [ -z "$hasNginx" ]; then
  echo "nginx未安装"
  installNginx
else
  echo "nginx已安装"
  # 判断是否启动
  checkStarted
  if [ -z "$isStart" ]; then
    startNginx
  else
    echo "nginx已启动"
    ps aux | grep nginx
  fi
fi