echo "是否要更新系统："
select opt in "是" "否"; do
  case $opt in
  "是")
    #yum clean all
    yum -y update
    yum -y install vim wget pcre pcre-devel zlib zlib-devel gcc gcc-c++ openssl openssl-devel automake autoconf libtool make sssd
    break
    ;;
  "否")
    break
    ;;
  esac
done
