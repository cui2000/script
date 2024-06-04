#! /bin/bash
# 此脚本用于安装plex服务

function enableService() {
  # 开机启动
  systemctl enable plexmediaserver.service
  systemctl start plexmediaserver.service

  # 提示
  echo "第一次使用需要通过ssh转发端口，本地putty运行命令："
  echo "ssh root@服务器IP -L 8888:localhost:32400"
  echo "输入正确的密码后，再去浏览器里打开localhost:8888/web进入即可"
}

hasPlex=$(systemctl list-unit-files | grep plexmediaserver)
if [ -z "$hasPlex" ]; then
  rootDir=/home/soft/plex
  mkdir -p "$rootDir"
  cd $rootDir
  # 下载安装
  curl -o plexmediaserver-1.40.2.8395-c67dce28e.x86_64.rpm https://downloads.plex.tv/plex-media-server-new/1.40.2.8395-c67dce28e/redhat/plexmediaserver-1.40.2.8395-c67dce28e.x86_64.rpm
  yum -y install plexmediaserver-1.40.2.8395-c67dce28e.x86_64.rpm

  # 等待安装完成，否则可能文件夹还没有建立
  sleep 3
  # 下载插件
  wget -O XBMCnfoMoviesImporter.bundle.zip https://github.com/gboudreau/XBMCnfoMoviesImporter.bundle/archive/refs/heads/master.zip
  unzip XBMCnfoMoviesImporter.bundle.zip
  cp -rf XBMCnfoMoviesImporter.bundle-master /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/XBMCnfoMoviesImporter.bundle

  wget -O JAVnfoMoviesImporter.bundle.zip https://github.com/ddd354/JAVnfoMoviesImporter.bundle/archive/refs/heads/master.zip
  unzip JAVnfoMoviesImporter.bundle.zip
  cp -rf JAVnfoMoviesImporter.bundle-master /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Plug-ins/JAVnfoMoviesImporter.bundle

  rm -rf XBMCnfoMoviesImporter*
  rm -rf JAVnfoMoviesImporter*
  # 开机启动
  enableService
else
  echo "plex已安装，是否要卸载："
  select opt in "是" "否"; do
    case $opt in
    "是")
      systemctl stop plexmediaserver
      systemctl disable plexmediaserver
      yum -y remove plexmediaserver
      rm -rf /var/lib/plexmediaserver
      rm -rf /usr/share/doc/plexmediaserver
      yum -y autoremove
      break
      ;;
    "否")
      enableService
      break
      ;;
    esac
  done
fi
