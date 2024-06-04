#!/bin/sh
# 用于设置ssl证书
rootDir=/etc/trojan-go
updateSh=$rootDir/updateGeoData.sh
function install() {
  systemDir=/usr/lib/systemd/system
  # 创建用户
  curl -sSL https://raw.githubusercontent.com/cui2000/script/dev/vps/createSystemUser.sh | bash -s "trojan" "certusers"
  # 下载
  wget -O trojan-go-linux-amd64.zip https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
  # 解压
  unzip trojan-go-linux-amd64.zip -d $rootDir
  # 复制服务器配置文件
  cp -f $rootDir/example/server.json $rootDir
  # 复制 trojan-go.service 到 $systemDir
  cp -f $rootDir/example/trojan-go.service $systemDir
  # 修改启动命令：
  # 使用bash的参数扩展进行替换
  rootDir_escaped=${rootDir//\//\\\/}

  sed -i "s/ExecStart=.*/ExecStart=$rootDir_escaped\/trojan-go -config $rootDir_escaped\/server.json/g" $systemDir/trojan-go.service
  sed -i "s/User=.*/User=trojan/g" $systemDir/trojan-go.service
  # 非root用户启动Trojan，Linux默认不允许非root用户启动的进程监听1024以下的端口，除非为每一个二进制文件显式声明
  setcap CAP_NET_BIND_SERVICE=+eip $rootDir/trojan-go
  # 创建更新geoip和geosite的定时任务
  createUpdateShell
  addCrontab
  # 授权
  chown -R trojan:certusers $rootDir
  # 红色字体提示
  echo -e "\033[31m----请修改\033[0m\033[32m$rootDir/server.json\033[0m\033[31m后执行以下命令：----\033[0m"
  echo -e "给证书文件夹（myCertDir替换为自己的证书文件夹）授权\033[31m（如果有必要）\033[0m"
  echo "chown -R trojan:certusers myCertDir"
  echo "chmod -R 750 myCertDir"
  echo "开机启动"
  echo "systemctl daemon-reload"
  echo "systemctl enable trojan-go"
  echo "systemctl start trojan-go"
}

function createUpdateShell() {
  if [ ! -f "$updateSh" ]; then
    touch $updateSh
    echo "
cd $rootDir
curl -o geoip.dat.new https://github.com/Loyalsoldier/geoip/releases/download/latest/geoip.dat
# 检查下载是否成功
if [ \$? -eq 0 ]; then
  cp -f geoip.dat.new geoip.dat
fi

curl -o geoip-only-cn-private.dat.new https://github.com/Loyalsoldier/geoip/releases/download/latest/geoip-only-cn-private.dat
if [ \$? -eq 0 ]; then
  cp -f geoip-only-cn-private.dat.new geoip-only-cn-private.dat
fi

curl -o geosite.dat.new https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
if [ \$? -eq 0 ]; then
  cp -f geosite.dat.new geosite.dat
fi
# 授权
chown -R trojan:certusers $rootDir
" >$updateSh
  fi
}

# 添加定时任务
function addCrontab() {
  hasCrontab=$(crontab -l | grep "$updateSh")
  if [ -z "$hasCrontab" ]; then
    echo "创建定时任务，每周五执行"
    # 添加定时任务，每周五执行
    getGeoData="0 0 * * 5 bash $updateSh"
    # 添加新的计划任务到crontab
    (
      crontab -l
      echo "$getGeoData"
    ) | crontab -
  fi
}

installed=$(systemctl list-unit-files | grep trojan-go)
if [ -z "$installed" ]; then
  install
else
  echo "已安装trojan-go"
  systemctl status trojan-go
fi
