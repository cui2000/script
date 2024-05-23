#! /bin/bash
# 此脚本用于安装prometheus的node_exporter

# 查看SELinux模式，如果是enforcing，在运行中会因为权限出问题
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/checkSestatus.sh)"

# 初始化
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/init.sh)"

# 设置根目录
rootPath=/home/soft/prometheus/module

# 下载
echo "下载alertmanager，下载目录：$rootPath"
wget -qP $rootPath https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz

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
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/alertmanager.service

echo "启动alertmanager..."
#刷新
systemctl daemon-reload
# 开机自启
systemctl enable alertmanager.service
# 启动
systemctl start alertmanager
# 判断是否启动成功
if [ -z "$(ps aux | grep alertmanager | grep -v grep)" ]; then
  echo "启动alertmanager失败"
else
  echo "启动alertmanager成功"
  echo "alertmanager需要开放9093端口，请访问http://ip:9093"
fi
