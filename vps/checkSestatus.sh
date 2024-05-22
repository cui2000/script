#! /bin/bash
# 此脚本用于检查SELinux模式，某些应用在enforcing下会因为权限出问题

# 查看SELinux模式，如果是enforcing，在运行中会因为权限出问题
seStatus=$(sestatus | grep "Current mode" | awk '{print $3}')
if [ "$seStatus" = "enforcing" ]; then
  echo "请编辑/etc/selinux/config修改SELinux模式为permissive"
  exit 0
fi