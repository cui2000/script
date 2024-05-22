#! /bin/bash
# 此脚本用于安装prometheus的node_exporter

# 初始化
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/init.sh)"

# 设置根目录
rootPath=/home/soft/prometheus/module

# 下载
echo "下载pushgateway，下载目录：$rootPath"
wget -qP $rootPath https://github.com/prometheus/pushgateway/releases/download/v1.8.0/pushgateway-1.8.0.linux-amd64.tar.gz

# 安装
echo "解压pushgateway"
tar -zxf $rootPath/pushgateway-1.8.0.linux-amd64.tar.gz -C $rootPath

homePath=$rootPath/pushgateway-1.8.0.linux-amd64
echo "安装pushgateway为服务"
echo "[Unit]
Description=Pushgateway
Documentation=https://www.prometheus.io/docs/instrumenting/pushing/
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
WorkingDirectory=$homePath
ExecStart=$homePath/pushgateway
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/pushgateway.service

echo "启动pushgateway..."
#刷新
systemctl daemon-reload
# 开机自启
systemctl enable pushgateway.service
# 启动
systemctl start pushgateway
# 判断是否启动成功
if [ -z "$(ps aux | grep pushgateway | grep -v grep)" ]; then
  echo "启动pushgateway失败"
else
  echo "启动pushgateway成功"
  echo "pushgateway需要开放9091端口，请访问http://ip:9091"
fi