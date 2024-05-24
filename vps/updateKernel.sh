#! /bin/bash
# 此脚本用于更新系统并安装必备应用

function update() {
  rpm_path=""
  is8=$(cat /etc/redhat-release | grep "CentOS .* 8")
  is9=$(cat /etc/redhat-release | grep "CentOS .* 9")
  if [ ! -z "$is8" ]; then
    rpm_path="https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm"
  elif [ ! -z "$is9" ]; then
    rpm_path="https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm"
  else
    echo "暂时只支持CentOS 8,9"
    exit 0
  fi
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  yum -y install $rpm_path
  yum --enablerepo=elrepo-kernel install kernel-ml -y
  reboot
}
update
