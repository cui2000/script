#! /bin/bash
# 此脚本用于设置防火墙，默认zone是public
zone="$1"
if [ -z "$zone" ]; then
  zone="public"
fi

function showPorts() {
  echo "端口信息："
  firewall-cmd --zone=public --list-all | grep ports
}

while [ true ]; do
  op="show"
  echo "请选择操作："
  select opt in "开放端口" "移除端口" "显示端口" "退出"; do
    case $opt in
    "开放端口")
      op="add"
      break
      ;;
    "移除端口")
      op="remove"
      break
      ;;
    "显示端口")
      #    showPorts
      break
      ;;
    "退出")
      exit 0
      break
      ;;
    esac
  done

  if [ "add" = $op ] || [ "remove" = $op ]; then
    echo -n "请输入端口："
    read portInfo
    for item in $portInfo; do
      echo -n "操作端口：$item "
      firewall-cmd --permanent --zone=$zone --$op-port=$item
    done
    echo -n "刷新防火墙 "
    firewall-cmd --reload
    showPorts
  else
    showPorts
  fi
done
