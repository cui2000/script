#!/bin/sh
# 计算要设置的虚拟内存
function calcSwapMem() {
  let total=$1
  let swap=$2
  # 大于等于2G，设置内存+2，否则*2
  if [ $total -gt 1500 ]; then
    swap=$(( ((total / 1000 + 1)) * 1024 + 2048 ))
  else
    swap=$(( ((total / 256 + 1)) * 512 ))
  fi
  echo $swap
}

# 设置虚拟内存
function setSwapMem() {
  echo "创建虚拟内存分区文件"
  swapfile="/var/swapfile"
  dd if=/dev/zero of=$swapfile bs=1M count=$1
  echo "格式化为虚拟内存分区文件"
  mkswap $swapfile
  echo "启用虚拟内存分区"
  swapon $swapfile
  echo "添加开机启动"
  echo "$swapfile swap swap defaults 0 0" >> /etc/fstab
  chmod 0600 $swapfile
  echo "虚拟内存文件为：$swapfile"
}

# 关闭虚拟内存
function removeSwapMem() {
  swapfile=$(swapon --show | awk 'NR==2 {print $1}')
  echo "关闭虚拟内存"
  swapoff -a
  echo "删除虚拟内存文件$swapfile"
  rm -f $swapfile
  echo "删除虚拟内存开机启动"
  sed -i '/ swap swap /d' /etc/fstab
}

# 重新设置虚拟内存
function resetSwapMem() {
  removeSwapMem
  echo "计算虚拟内存大小"
  let swapMem=$(calcSwapMem $totalMem $swapMem)
  echo "设置虚拟内存为：$swapMem M"
  setSwapMem $swapMem
}

totalMem=$(free -m | awk '/Mem/{print $2}')
swapMem=$(free -m | awk '/Swap/{print $2}')

echo "内存：$totalMem M"
echo "虚拟内存：$swapMem M"

if [ $swapMem = 0 ]; then
  let swapMem=$(calcSwapMem $totalMem $swapMem)
  echo "没有虚拟内存，是否设置，虚拟内存将设置为：$swapMem M"
  select opt in "是" "否"; do
    case $opt in
      "是")
        setSwapMem $swapMem
        break
        ;;
      "否")
        break
        ;;
    esac
  done
else
  echo "已有虚拟内存，是否重新设置？"
  select opt in "是" "否" "关闭虚拟内存"; do
    case $opt in
      "是")
        resetSwapMem
        break
        ;;
      "否")
        break
        ;;
      "关闭虚拟内存")
        removeSwapMem
        break
        ;;
    esac
  done
fi