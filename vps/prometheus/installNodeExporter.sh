#! /bin/bash
# 此脚本用于安装prometheus的node_exporter

# 脚本目录及配置文件
script_file="/home/soft/script/config.sh"

# 初始化
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/init.sh)"

isInstall=$(sh "$script_file" "get" "installNodeExporter")
if [ "$isInstall" = "1" ]; then
  echo "node exporter已安装"
  exit 0
fi


# 设置根目录
rootPath=/home/soft/prometheus/module

# 下载
echo "下载node_exporter，下载目录：$rootPath"
wget -P $rootPath https://github.com/prometheus/node_exporter/releases/download/v1.8.0/node_exporter-1.8.0.linux-amd64.tar.gz

# 安装
echo "解压node_exporter"
tar -zxf $rootPath/node_exporter-1.8.0.linux-amd64.tar.gz -C $rootPath

homePath=$rootPath/node_exporter-1.8.0.linux-amd64
echo "安装node_exporter为服务"
echo "[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
WorkingDirectory=$homePath
ExecStart=$homePath/node_exporter
ExecStartPre=cd $homePath
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/node_exporter.service

# 修改目录属主
chown -R prometheus:prometheus /home/soft/prometheus
echo "启动node_exporter..."
#刷新
systemctl daemon-reload
# 开机自启
systemctl enable node_exporter.service
# 启动
systemctl start node_exporter
# 等待启动
sleep 2
# 判断是否启动成功
if [ -z "$(ps aux | grep node_exporter | grep -v grep)" ]; then
  echo "启动node_exporter失败"
else
  echo "启动node_exporter成功"
  echo "node_exporter需要开放9100端口，请访问http://ip:9100"
  echo "如果想注册到consul以使用自动发现服务，请执行："
  echo "curl -X PUT -d '{
    \"ID\": \"node_exporter-instance-1\",
    \"Name\": \"node-exporter\",
    \"Address\": \"node_exporter_ip\",
    \"Port\": 9100,
    \"Tags\": [\"monitoring\"],
    \"Checks\": [
        {
            \"HTTP\": \"http://node_exporter_ip:9100/metrics\",
            \"Interval\": \"10s\"
        }
    ]
}' http://consulIp:8500/v1/agent/service/register"
fi

# 记录配置
sh "$script_file" "set" "installNodeExporter" "1"
