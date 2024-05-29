#! /bin/bash
# 此脚本用于安装prometheus的node_exporter

# 脚本目录及配置文件
script_file="/home/soft/script/config.sh"

# 初始化
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/init.sh)"

isInstall=$(sh "$script_file" "get" "installAlertmanager")
if [ "$isInstall" = "1" ]; then
  echo "alertmanager已安装"
  exit 0
fi

# 设置根目录
rootPath=/home/soft/prometheus/module

# 下载
echo "下载alertmanager，下载目录：$rootPath"
wget -P $rootPath https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz

# 安装
echo "解压alertmanager"
tar -zxf $rootPath/alertmanager-0.27.0.linux-amd64.tar.gz -C $rootPath

homePath=$rootPath/alertmanager-0.27.0.linux-amd64
echo "安装alertmanager为服务"
echo "[Unit]
Description=Alertmanager
Documentation=https://prometheus.io/docs/alerting/latest/alertmanager/
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
WorkingDirectory=$homePath
ExecStart=$homePath/alertmanager
ExecStartPre=cd $homePath
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/alertmanager.service

# 修改目录属主
chown -R prometheus:prometheus /home/soft/prometheus
echo "启动alertmanager..."
#刷新
systemctl daemon-reload
# 开机自启
systemctl enable alertmanager.service
# 启动
systemctl start alertmanager
# 判断是否启动成功
isStart=$(ps aux | grep alertmanager | grep -v grep)
if [ -z "$isStart" ]; then
  echo "启动alertmanager失败"
else
  echo "启动alertmanager成功"
  echo "alertmanager需要开放9093端口，请访问http://ip:9093"
fi

# 记录配置
sh "$script_file" "set" "installAlertmanager" "1"
