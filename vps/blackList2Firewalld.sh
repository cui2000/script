#! /bin/bash
# 此脚本用于firewalld服务，自动将超过10次失败的ip放入黑名单

hasFirewalld=$(systemctl list-unit-files | grep firewalld)
if [ -z "$hasFirewalld" ]; then
  echo -n "firewalld服务未安装，是否安装？是（输入1），否（任意输入）："
  read isInstall
  if [ "$isInstall" = "1" ]; then
    # 避免手误，关闭了ssh，安装防火墙后无法连接服务器
    systemctl start sshd
    # 安装firewalld
    yum -y install firewalld
    systemctl enable firewalld
    systemctl start firewalld
  else
    exit 0
  fi
fi

# 创建黑名单文件
ipAccess="/home/ipAccess.list"
ipBlack="/home/blackIp.txt"
# 黑名单的ipset名称
ipsetName=blacklist
# 获取当前运行脚本的路径
script_path=$(readlink -f "$0")

# 如果文件不存在，则创建文件
if [ ! -f "$ipAccess" ]; then
  echo "创建ip访问统计文件：$ipAccess"
  touch "$ipAccess"
fi
if [ ! -f "$ipBlack" ]; then
  echo "创建黑名单文件：$ipBlack"
  touch "$ipBlack"
fi

# 统计超过10次登录失败的ip
function setBlackList() {
  echo "统计超过10次登录失败的ip并写入文件$ipAccess"
  cat /var/log/secure | awk '/Failed/{print $(NF-3)}' | sort | uniq -c | awk '{print $2"="$1;}' >$ipAccess
  for i in $(cat $ipAccess); do
    IP=$(echo $i | awk -F= '{print $1}')
    NUM=$(echo $i | awk -F= '{print $2}')
    # 统计出来会有flush，原因待查
    if [ "flush" = "$IP" ]; then
        continue
    fi
    if [ $NUM -gt 10 ]; then
      #grep $IP /etc/hosts.deny > /dev/null
      grep $IP $ipBlack >/dev/null
      if [ $? -gt 0 ]; then
        #echo "sshd:$IP:deny" >> /etc/hosts.deny
        echo "$IP" >>$ipBlack
      fi
    fi
  done
}

# 添加定时任务
function addCrontab() {
  # 如果没有则创建
  hasCrontab=$(crontab -l | grep "$script_path")
  if [ -z "$hasCrontab" ]; then
    echo "创建定时任务，10分钟执行一次：$script_path"
    chmod +x $script_path
    # 添加定时任务，10分钟一次
    deny="*/10 * * * * sh $script_path"
    # 添加新的计划任务到crontab
    (
      crontab -l
      echo "$deny"
    ) | crontab -
  fi
}

function installBlackList() {
  # 如果没有则创建
  hasBlackIpset=$(firewall-cmd --get-ipsets | grep $ipsetName)
  if [ -z "$hasBlackIpset" ]; then
    # 创建一个ipset
    # type选项中的hash:net对应的是ipv4的网络环境
    # 要创建用于IPv6的IP集，请添加--option = family = inet6选项
    echo -n "创建ipset：$ipsetName 用于黑名单 "
    firewall-cmd --permanent --new-ipset=$ipsetName --type=hash:net
    # 在drop区域中定义一条源规则，将$ipsetName的地址集作为源规则的源IP
    echo -n "将ipset：$ipsetName 添加到zone:drop "
    firewall-cmd --permanent --zone=drop --add-source=ipset:$ipsetName
    #firewall-cmd --permanent --zone=public --add-rich-rule="rule family='ipv4' source ipset=blacklist drop"
    #firewall-cmd --reload
  fi
  # 统计超过10次登录失败的ip并写入文件
  setBlackList
  echo -n "更新黑名单 "
  # 使用--add-entries-from-file选项将$ipBlack的内容导入到$ipsetName的ipset空间中
  firewall-cmd --permanent --ipset=$ipsetName --add-entries-from-file=$ipBlack
  echo -n "刷新防火墙 "
  firewall-cmd --reload

  # 创建定时任务
  addCrontab
}

# 设置黑名单
isRunning=$(firewall-cmd --state)
if [ "running" = "$isRunning" ]; then
  installBlackList
else
  echo "firewalld服务未启动，已自动启动"
  echo "为避免开启防火墙后导致服务不可用，请检查防火墙配置:firewall-cmd --list-all-zone"
  # 避免手误，关闭了ssh，安装防火墙后无法连接服务器
  systemctl start sshd
  # 启动firewalld
  systemctl enable firewalld
  systemctl start firewalld
  installBlackList
fi
