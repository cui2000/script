#! /bin/bash
# 此脚本用于安装prometheus服务

# 脚本目录及配置文件
script_file="/home/soft/script/config.sh"

# 初始化
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/init.sh)"
#curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/init.sh | bash -s "1"

isInstall=$(sh "$script_file" "get" "installPrometheus")
if [ "$isInstall" = "1" ]; then
  echo "prometheus已安装"
  exit 0
fi

#设置根目录
rootPath=/home/soft/prometheus

# 下载
echo "下载prometheus，下载目录：$rootPath"
mkdir -p $rootPath
wget -P $rootPath https://github.com/prometheus/prometheus/releases/download/v2.45.5/prometheus-2.45.5.linux-amd64.tar.gz

# 安装
echo "解压prometheus"
cd $rootPath
tar -zxf $rootPath/prometheus-2.45.5.linux-amd64.tar.gz -C $rootPath

# 启动
programPath=$rootPath/prometheus-2.45.5.linux-amd64
echo "安装prometheus为服务"
echo "[Unit]
Description=Prometheus
Documentation=https://www.prometheus.io/docs/introduction/overview/
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
WorkingDirectory=$programPath
ExecStart=$programPath/prometheus \\
  --config.file=$programPath/prometheus.yml \\
  --storage.tsdb.path=$programPath/data \\
  --web.enable-lifecycle
ExecStartPre=setenforce 0
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/prometheus.service

echo "启动prometheus..."
#刷新
systemctl daemon-reload
# 开机自启
systemctl enable prometheus.service
# 启动
systemctl start prometheus
# 安装组件
if [ -z "$(ps aux | grep prometheus | grep -v grep)" ]; then
  echo "启动prometheus失败"
else
  echo "启动prometheus成功"
  echo "prometheus需要开放9090端口，请访问http://ip:9090"
  # 记录配置
  sh "$script_file" "set" "installPrometheus" "1"
  # 安装组件
  echo -n "是否要安装node_exporter，altermanager，pushgateway组件？是（输入1），否（任意输入）："
  read isInstall
  if [ $isInstall = "1" ]; then
    # 安装组件
    curl -sSL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/installNodeExporter.sh | bash -s "0"
    curl -sSL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/installAlertManager.sh | bash -s "0"
    curl -sSL https://raw.githubusercontent.com/cui2000/script/dev/vps/prometheus/installPushGateway.sh | bash -s "0"
  fi
fi

#runuser - grafana -c "nohup ./bin/grafana server > ./grafana.log &"
