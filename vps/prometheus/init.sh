#! /bin/bash
# 此脚本用于初始化prometheus服务的用户和组

function createUser() {
  # 判断用户是否存在
  username="prometheus"
  if id -u "$username" >/dev/null 2>&1; then
    echo "使用用户$username"
  else
    # 创建不能登录的用户
    echo "创建用户$username"
    useradd -s /sbin/nologin -M $username
  fi

  # 判断组是否存在
  groupname="prometheus"
  if getent group "$groupname" >/dev/null 2>&1; then
    echo "使用用户组$groupname"
  else
    echo "创建用户组$groupname"
    groupadd -r $groupname
  fi
}
needInit="1"
if [ ! -z "$1" ]; then
  needInit="$1"
fi
if [ $needInit != "0" ]; then
  # 升级系统
  eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/update.sh)"

  # 创建用户
  createUser

  # 建立文件夹
  mkdir -p /home/soft/prometheus/module

  # 修改目录属主
  chown -R prometheus:prometheus /home/soft/prometheus
fi
