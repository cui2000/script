#! /bin/bash
# 此脚本用于安装docker-compose服务

hasDocker=$(systemctl list-unit-files | grep docker)
if [ -z "$hasDocker" ]; then
  echo "请先安装docker"
else
  dockerCliPluginsPath=""
  if [ -d "/usr/local/lib/docker/cli-plugins" ]; then
    dockerCliPluginsPath="/usr/local/lib/docker/cli-plugins"
  elif [ -d "/usr/local/libexec/docker/cli-plugins" ]; then
    dockerCliPluginsPath="/usr/local/libexec/docker/cli-plugins"
  elif [ -d "/usr/lib/docker/cli-plugins" ]; then
    dockerCliPluginsPath="/usr/lib/docker/cli-plugins"
  elif [ -d "/usr/libexec/docker/cli-plugins" ]; then
    dockerCliPluginsPath="/usr/libexec/docker/cli-plugins"
  fi
  if [ -z "$dockerCliPluginsPath" ]; then
    echo "未找到docker的cli-plugins目录"
  else
    if [ -f "$dockerCliPluginsPath/docker-compose" ]; then
      echo "docker-compose已安装"
    else
      wget -P $dockerCliPluginsPath -O docker-compose https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64
      chmod +x $dockerCliPluginsPath/docker-compose
    fi
    docker compose version
  fi
fi
