#! /bin/bash
# 此脚本用于更新系统并安装必备应用

function update() {
  os=""
  osInfoPath="/etc/redhat-release"
  if [ ! -z "$(cat $osInfoPath | grep CentOS)" ]; then
    os="CentOS"
  elif [ ! -z "$(cat $osInfoPath | grep AlmaLinux)" ]; then
    os="AlmaLinux"
  else
    echo "暂时只支持CentOS/AlmaLinux 8,9"
    exit 0
  fi

  echo "升级系统内核会重启，重启后通过uname -r查看是否升级成功"
  echo "通过grubby --info=ALL查看所有内核"
  echo "通过grubby --default-kernel查看启动内核"
  echo "通过grubby --set-default=xxx设置默认启动内核"
  echo "通过rpm -qa | grep kernel查看所有内核"
  echo "通过yum remove删除旧内核"
  rpm_path=""
  is8=$(cat /etc/redhat-release | grep "$os .* 8")
  is9=$(cat /etc/redhat-release | grep "$os .* 9")
  if [ ! -z "$is8" ]; then
    rpm_path="https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm"
    # 使用其他镜像源
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
  elif [ ! -z "$is9" ]; then
    rpm_path="https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm"
  else
    echo "暂时只支持8,9"
    exit 0
  fi
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  yum -y install $rpm_path
  yum --enablerepo=elrepo-kernel install kernel-ml -y
  echo "安装内核完毕，重启"
  reboot
}
update
