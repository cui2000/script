#! /bin/bash
# 此脚本用于安装grafana服务

# 脚本目录及配置文件
script_file="/home/soft/script/config.sh"

# 查看SELinux模式，如果是enforcing，在运行中会因为权限出问题
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/checkSestatus.sh)"

# 更新系统
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/update.sh)"

isInstall=$(bash "$script_file" "get" "installGrafana")
if [ "$isInstall" = "1" ]; then
  echo "grafana已安装"
  exit 0
fi

# 创建用户
curl -sSL https://raw.githubusercontent.com/cui2000/script/dev/vps/createSystemUser.sh | bash -s "grafana"

#设置根目录
rootPath=/home/soft/grafana
mkdir -p $rootPath

# 下载
echo "下载grafana，下载目录：$rootPath"
wget -P $rootPath https://dl.grafana.com/enterprise/release/grafana-enterprise-11.0.0.linux-amd64.tar.gz

# 安装
echo "解压grafana到$rootPath"
tar -zxf $rootPath/grafana-enterprise-11.0.0.linux-amd64.tar.gz -C $rootPath

# 没有插件文件夹启动会报错
homePath=$rootPath/grafana-v11.0.0
mkdir -p $homePath/data/plugins
chown -R grafana:grafana $homePath

# 启动
echo "安装grafana为服务"
echo "[Unit]
Description=Grafana
Documentation=https://grafana.com/docs/grafana/latest/
After=network.target

[Service]
Type=notify
User=grafana
Group=grafana
WorkingDirectory=$homePath
ExecStart=$homePath/bin/grafana server --homepath=$homePath
ExecStartPre=cd $homePath
Restart=on-failure

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/grafana.service

echo "启动grafana..."
#刷新
systemctl daemon-reload
# 开机自启
systemctl enable grafana.service
# 启动
systemctl start grafana
# 等待启动
isStart=$(ps aux | grep grafana | grep -v grep)
if [ -z "$isStart" ]; then
  echo "启动grafana失败"
else
  echo "启动grafana成功"
  echo "grafana需要开放3000端口，请访问http://ip:3000，默认用户名密码是admin"
fi

# 记录配置
bash "$script_file" "set" "installGrafana" "1"

## 不然在无权限的目录启动会报错
#cd $grafanaHomePath
#runuser - grafana -c "nohup ./bin/grafana server > ./grafana.log &"
