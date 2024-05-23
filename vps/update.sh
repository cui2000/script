#! /bin/bash
# 此脚本用于更新系统并安装必备应用

function update() {
  yum clean all
  yum -y update
  yum -y install vim wget pcre pcre-devel zlib zlib-devel gcc gcc-c++ openssl openssl-devel automake autoconf libtool make sssd net-tools
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
    sh "$script_file"
  else
    echo "Failed to download script from $urlPath"
  fi
fi

isUpdate=$(sh "$script_file" "get" "isUpdate")
if [ "$isUpdate" != "1" ]; then
  update
  sh "$script_file" "set" "isUpdate" "1"
fi
