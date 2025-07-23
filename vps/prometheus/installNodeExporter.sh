#! /bin/bash
# 此脚本用于安装prometheus的node_exporter

# node_exporter启动标识
isStart=1

# 是否启动
function checkStarted(){
  isStart=$(ps aux | grep node_exporter | grep -v grep)
}

# 启动
function startNodeExporter(){
  echo "启动node_exporter..."
  systemctl enable --now node_exporter
  sleep 1
  checkStarted
  if [ -z "$isStart" ]; then
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
}

# 创建用户
function createUser() {
  username="$1"
  groupname="$2"

  # 如果没有输入组名，默认同用户名
  if [ -z "$groupname" ]; then
    groupname="$username"
  fi

  # 判断用户是否存在
  if id -u "$username" >/dev/null 2>&1; then
    echo "使用用户$username"
  else
    # 创建不能登录的系统用户，不建立同名用户组，不建立文件夹
    echo "创建用户$username"
    useradd -NMrs /sbin/nologin $username
  fi

  # 判断组是否存在
  if getent group "$groupname" >/dev/null 2>&1; then
    echo "使用用户组$groupname"
  else
    echo "创建用户组$groupname"
    groupadd -r $groupname
  fi

  # 添加用户到用户组
  usermod -aG $groupname $username
}

# 安装应用
function installNodeExporter(){
  # 检测系统
  version=1.9.1
  arch=$(uname -m)
  dirName=""
  # 不是AMD
  if [ "$arch" = "x86_64" ]; then
    dirName=node_exporter-$version.linux-amd64
  elif [ "$arch" = "aarch64" ]; then
    dirName=node_exporter-$version.linux-arm64
  else
    echo "只支持amd和arm"
    exit 0
  fi

  # 创建用户
  createUser "prometheus"

  # 下载
  downloadUrl="https://github.com/prometheus/node_exporter/releases/download/v$version/$dirName.tar.gz"
  # 设置根目录
  rootPath=/home/soft/prometheus/module
  echo "下载node_exporter，下载目录：$rootPath"
  wget -P $rootPath "https://github.com/prometheus/node_exporter/releases/download/v$version/$dirName.tar.gz"

  # 安装
  echo "解压node_exporter"
  tar -zxf $rootPath/$dirName.tar.gz -C $rootPath

  homePath=$rootPath/$dirName
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
  Restart=on-failure

  [Install]
  WantedBy=multi-user.target" >/etc/systemd/system/node_exporter.service

  # 修改目录宿主
  chown -R prometheus:prometheus /home/soft/prometheus

  # 启动
  systemctl daemon-reload
  startNodeExporter
}

hasNodeExporter=$(systemctl list-unit-files | grep node_exporter)
if [ -z "$hasNodeExporter" ]; then
  echo "node_exporter未安装"
  installNodeExporter
else
  echo "node_exporter已安装"
  # 判断是否启动
  checkStarted
  if [ -z "$isStart" ]; then
    startNodeExporter
  else
    echo "node_exporter已启动"
    ps aux | grep node_exporter
  fi
fi