#! /bin/bash
# 此脚本用于初始化prometheus服务的用户和组

# 查看SELinux模式，如果是enforcing，在运行中会因为权限出问题
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/checkSestatus.sh)"
# 升级系统
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/update.sh)"
# 创建用户
curl -sSL https://raw.githubusercontent.com/cui2000/script/dev/vps/createSystemUser.sh | bash -s "prometheus"
# 建立文件夹
mkdir -p /home/soft/prometheus/module
# 修改目录属主
chown -R prometheus:prometheus /home/soft/prometheus
