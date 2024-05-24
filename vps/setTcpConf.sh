#!/bin/sh
# 设置bbr等tcp参数

# 设置
function setOrReplace() {
  key="$1"
  value="$2"
  exist=$(cat /etc/sysctl.conf | grep $key=)
  if [ -z "$exist" ]; then
    echo "$key=$value" >>/etc/sysctl.conf
  else
    sed -i "s/$key=.*/$key=$value/g" /etc/sysctl.conf
  fi
}

# 截取版本
version=$(uname -r)
IFS='.' read -ra info <<<"$version"
# 恢复IFS的默认值（通常是换行符和空格等）
unset IFS
# 判断版本
bigVersion=${info[0]}
smallVersion=${info[1]}
faskopen="0"
bbr="0"
qdisc="fq"
if [ $bigVersion -gt 4 ]; then
  faskopen="1"
  bbr="1"
  qdisc="cake"
elif [ $bigVersion -eq 4 ]; then
  if [ $smallVersion -lt 9 ]; then
    echo "bbr需要的最低内核版本为4.9"
  else
    bbr="1"
    qdisc="fq"
    if [ $smallVersion -gt 10 ]; then
      # 4.11版本以上才支持
      faskopen="1"
    fi
    if [ $smallVersion -gt 11 ]; then
      # 4.12版本以上才支持
      qdisc="fq_codel"
    fi
    if [ $smallVersion -gt 18 ]; then
      # 4.19版本以上才支持
      qdisc="cake"
    fi
  fi
fi
if [ "$bbr" = "1" ]; then
  setOrReplace "net.ipv4.tcp_congestion_control" "bbr"
  setOrReplace "net.core.default_qdisc" "$qdisc"
  if [ "$faskopen" = "1" ]; then
    # faskopen
    echo 3 >/proc/sys/net/ipv4/tcp_fastopen
    setOrReplace "net.ipv4.tcp_fastopen" "3"
  fi
  # 生效
  sysctl -p
fi
