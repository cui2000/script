#! /bin/bash
# 此脚本用于安装plex服务

hasRclone=$(systemctl list-unit-files | grep rclone)
if [ -z "$hasRclone" ]; then
  rootDir=/home/soft/rclone
  dataDir=$rootDir/data/gdrive
  cacheDir=$rootDir/data/cache
  confDir=$rootDir/.config
  # 建立文件夹
  mkdir -p $confDir
  mkdir -p $dataDir
  mkdir -p $cacheDir
  cd $rootDir
  version=rclone-v1.66.0-linux-amd64
  wget -O $version.zip https://github.com/rclone/rclone/releases/download/v1.66.0/$version.zip
  unzip $version.zip

  #binary
  mv $version/rclone /usr/bin/rclone
  chmod 755 /usr/bin/rclone
  chown root:root /usr/bin/rclone
  #manual
  if ! [ -x "$(command -v mandb)" ]; then
    echo 'mandb not found. The rclone man docs will not be installed.'
  else
    mkdir -p /usr/local/share/man/man1
    cp $version/rclone.1 /usr/local/share/man/man1/
    mandb
  fi
  echo "[Unit]
Description=Rclone service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount --config $confDir/rclone.conf \\
  --log-file $rootDir/rclone.log --transfers 32 gd: $dataDir \\
  --copy-links --no-gzip-encoding --no-check-certificate \\
  --allow-other --allow-non-empty --default-permissions --file-perms 0777 --umask 0000 \\
  --vfs-cache-mode full --cache-dir $cacheDir \\
  --vfs-cache-max-size 5G --buffer-size 64M --dir-cache-time 6h \\
  --vfs-read-chunk-size 64M --vfs-read-chunk-size-limit 256M
Restart=on-abort
RestartSec=5

[Install]
WantedBy=multi-user.target" >/usr/lib/systemd/system/rclone.service

else
  echo "rclone已安装"
fi
#刷新
systemctl daemon-reload
# 开机启动
systemctl enable rclone.service
systemctl start rclone.service

#update version variable post install
version=$(rclone --version 2>>errors | head -n 1)

#cleanup
#rm -rf "$tmp_dir"

printf "\n${version} has successfully installed."
printf '\nNow run "rclone config" for setup. Check https://rclone.org/docs/ for more details.\n\n'
