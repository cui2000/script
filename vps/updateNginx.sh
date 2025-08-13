#! /bin/bash
# 此脚本用于升级nginx服务

# 判断版本
if nginx -v 2>&1 | awk -F'/' '{print $2}' | awk -F'.' '{exit ($1*1000 + $2 < 1028)}'; then
  echo "Nginx ≥ 1.28，不需升级"
  exit 0
fi

read -p "请输入nginx的sbin目录（默认为/usr/local/nginx/sbin）：" -r sbinPath
sbinPath=${sbinPath:-/usr/local/nginx/sbin}

# nginx下载到的目录
nginxPath="/home/soft"
mkdir -p "$nginxPath"
echo "nginx下载到$nginxPath"
cd $nginxPath
wget http://nginx.org/download/nginx-1.28.0.tar.gz
tar -xzf nginx-1.28.0.tar.gz
cd nginx-1.28.0
./configure \
  --with-http_stub_status_module \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_v3_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_ssl_preread_module \
  --with-threads \
  --with-file-aio
make
mv $sbinPath/nginx $sbinPath/nginx.old
cp ./objs/nginx $sbinPath/nginx
echo "升级"
make upgrade
sleep 1
echo "如果nginx进程不存在或升级失败，请手动启动"
ps aux|grep nginx