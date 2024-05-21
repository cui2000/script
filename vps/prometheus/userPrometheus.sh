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

usermod -aG $groupname $username
