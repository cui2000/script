#!/bin/sh
# 用于设置ssl证书

function setCertificate() {
  # 需要的应用
  yum install -y socat cronie
  systemctl start crond
  systemctl enable crond
  # 证书文件
  certPath=/usr/local/etc/certfiles
  mkdir -p $certPath
  echo -n "请输入你的域名："
  read domain
  echo -n "请输入cloudflare账号邮箱："
  read email
  echo -n "请输入cloudflare账号的Global API Key："
  read apiKey

  # 创建用户
  useradd -Nmrs /sbin/nologin "acme"
  groupadd -r "certusers"
  usermod -aG "certusers" "acme"
  # 授权
  chown -R acme:certusers $certPath
  chmod -R 750 $certPath
  # 切换用户
  su -l -s /bin/bash acme -c "curl  https://get.acme.sh | sh -s email=$email"
  echo -e "\033[31m请新打开终端执行以下指令：\033[0m"
  echo "su -l -s /bin/bash acme"
  echo "export CF_Key=$apiKey"
  echo "export CF_Email=$email"
  echo "acme.sh --issue --dns dns_cf -d $domain"
  echo "acme.sh --install-cert -d $domain --key-file $certPath/$domain.key --fullchain-file $certPath/$domain.crt"
  echo "exit"
  echo -e "\033[31m证书生成成功后请执行以下命令，让certusers用户组其他成员也能访问证书\033[0m"
  echo "chown -R acme:certusers $certPath"
  echo "chmod -R 750 $certPath"

}

echo "请先准备好域名和cloudflare的Global API Key，并确认域名没有使用cdn"
echo "是否设置："
select opt in "是" "否"; do
  case $opt in
  "是")
    setCertificate
    break
    ;;
  "否")
    break
    ;;
  esac
done
