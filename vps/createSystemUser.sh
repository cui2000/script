#! /bin/bash
# 此脚本用于创建不能登录的系统用户

function createUser() {
  username="$1"
  groupname="$2"
  # 不带参数
  if [ -z "$username" ]; then
    while [ -z "$username" ]; do
      echo -n "请输入要创建的用户名："
      read username
    done
    echo -n "请输入要创建的用户组（回车默认$username）："
    read groupname
  fi

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

# 创建用户
createUser "$1" "$2"