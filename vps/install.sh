#! /bin/bash
# 此脚本用于安装应用

# 脚本目录及配置文件
script_path=/home/soft/script
script_file="$script_path/config.sh"
config_path="$script_path/config.ini"

# 设置要下载的脚本的URL
SCRIPT_URL="https://raw.githubusercontent.com/cui2000/script/dev/vps"

mkdir -p $script_path

function init() {
  if [ ! -f "$script_file" ]; then
    mkdir -p $script_path
    url_path="$SCRIPT_URL/config.sh"
    curl -o "$script_file" "$url_path"
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
      # 执行下载的脚本
      sh "$script_file"
    else
      echo "Failed to download script from $urlPath"
      exit 0
    fi
  fi
}

function getScript() {
  script_file="$1"
  url_path="$2"
  if [ ! -f "$script_file" ]; then
    # 使用curl下载脚本到脚本目录
    curl -o "$script_file" --create-dirs "$url_path"
    # 检查下载是否成功
    if [ ! $? -eq 0 ]; then
      echo "Failed to download script from $urlPath"
      exit 0
    fi
  fi
}

#执行
function run() {
  fileName="$1"
  filePath="$script_path/$fileName"
  urlPath="$SCRIPT_URL/$fileName"
  getScript "$filePath" "$urlPath"
  sh "$filePath"
}
# 初始化配置
init

# 安装应用
while [ true ]; do
  echo "请选择："
  select opt in "设置虚拟内存" "防火墙自动添加黑名单" "安装docker" "安装nginx" \
    "安装Prometheus" "安装node exporter" "安装Grafana" \
    "安装plex" "安装rclone" "设置bbr和fastopen" "升级系统内核" "设置ssl证书" "退出"; do
    case $opt in
    "设置虚拟内存")
      run "setSwap.sh"
      break
      ;;
    "防火墙自动添加黑名单")
      run "blackList2Firewalld.sh"
      break
      ;;
    "安装nginx")
      run "installNginx.sh"
      break
      ;;
    "安装Prometheus")
      run "prometheus/install.sh"
      break
      ;;
    "安装node exporter")
      run "prometheus/installNodeExporter.sh"
      break
      ;;
    "安装Grafana")
      run "prometheus/installGrafana.sh"
      break
      ;;
    "安装docker")
      run "installDocker.sh"
      break
      ;;
    "安装plex")
      run "installPlex.sh"
      break
      ;;
    "安装rclone")
      run "installRclone.sh"
      break
      ;;
    "设置bbr和fastopen")
      run "setTcpConf.sh"
      break
      ;;
    "升级系统内核")
      run "updateKernel.sh"
      break
      ;;
    "设置ssl证书")
      run "setCertificate.sh"
      break
      ;;
    "退出")
      exit 0
      break
      ;;
    esac
  done
done
