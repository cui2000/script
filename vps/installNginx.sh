# ����
mkdir -p /home/soft
cd /home/soft
wget http://nginx.org/download/nginx-1.23.0.tar.gz

# ��װ
tar -xzf nginx-1.23.0.tar.gz
cd nginx-1.23.0
./configure --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-stream
make
make install

echo "��װnginxΪ����"
echo "[Unit]
Description=nginx service
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
PrivateTmp=true

[Install]
WantedBy=multi-user.target" >> /usr/lib/systemd/system/nginx.service

# ��������
systemctl enable nginx.service

# ����ϵͳ����
echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
source /etc/profile

# ����
cd /usr/local/nginx/sbin
./nginx