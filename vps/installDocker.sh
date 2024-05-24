#! /bin/bash
# 此脚本用于安装docker服务

hasDocker=$(systemctl list-unit-files | grep docker)
if [ -z "$hasDocker" ]; then
  filePath=$script_path/get-docker.sh
  curl -fsSL https://get.docker.com -o $filePath --create-dirs && sh $filePath
else
  echo "docker已安装"
fi
systemctl enable docker.service
systemctl start docker
