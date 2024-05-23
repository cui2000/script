#! /bin/bash
# 此脚本用于安装nginx服务

# 脚本目录及配置文件
script_file="/home/soft/script/config.sh"

# 先更新系统
eval "$(curl -sL https://raw.githubusercontent.com/cui2000/script/dev/vps/update.sh)"

isInstall=$(sh "$script_file" "get" "installNginx")
if [ "$isInstall" = "1" ]; then
  echo "nginx已安装"
  exit 0
fi

# 设置根目录
rootPath=/home/soft/nginx

# 下载
echo "下载目录：$rootPath"
mkdir -p $rootPath
wget -P $rootPath http://nginx.org/download/nginx-1.23.0.tar.gz

# 安装
cd $rootPath
tar -xzf nginx-1.23.0.tar.gz
cd $rootPath/nginx-1.23.0
./configure --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-stream
make
make install

echo "安装nginx为服务"
echo "[Unit]
Description=nginx service
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target" >> /usr/lib/systemd/system/nginx.service

#刷新
systemctl daemon-reload

# 开机自启
systemctl enable nginx.service

# 启动
systemctl start nginx

# 设置系统变量
echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
source /etc/profile

# 输出信息
echo "nginx下载在$rootPath"
echo "nginx启动文件是/usr/lib/systemd/system/nginx.service"

# 记录配置
sh "$script_file" "set" "installNginx" "1"