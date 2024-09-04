#!/bin/sh
# 设置bbr等tcp参数

# 设置
function setOrReplace() {
  key="$1"
  value="$2"
  exist=$(cat /etc/sysctl.conf | grep $key=)
  if [ -z "$exist" ]; then
    echo "$key=$value" >>/etc/sysctl.conf
  else
    sed -i "s/$key=.*/$key=$value/g" /etc/sysctl.conf
  fi
}

# 截取版本
version=$(uname -r)
IFS='.' read -ra info <<<"$version"
# 恢复IFS的默认值（通常是换行符和空格等）
unset IFS
# 判断版本
bigVersion=${info[0]}
smallVersion=${info[1]}
faskopen="0"
bbr="0"
qdisc="fq"
if [ $bigVersion -gt 4 ]; then
  faskopen="1"
  bbr="1"
  qdisc="cake"
elif [ $bigVersion -eq 4 ]; then
  if [ $smallVersion -lt 9 ]; then
    echo "bbr需要的最低内核版本为4.9"
  else
    bbr="1"
    qdisc="fq"
    if [ $smallVersion -gt 10 ]; then
      # 4.11版本以上才支持
      faskopen="1"
    fi
    if [ $smallVersion -gt 11 ]; then
      # 4.12版本以上才支持
      qdisc="fq_codel"
    fi
    if [ $smallVersion -gt 18 ]; then
      # 4.19版本以上才支持
      qdisc="cake"
    fi
  fi
fi
if [ "$bbr" = "1" ]; then
  setOrReplace "net.ipv4.tcp_congestion_control" "bbr"
  setOrReplace "net.core.default_qdisc" "$qdisc"
  if [ "$faskopen" = "1" ]; then
    # faskopen
    echo 3 >/proc/sys/net/ipv4/tcp_fastopen
    setOrReplace "net.ipv4.tcp_fastopen" "3"
  fi
  # TCP协议在接收数据时使用的缓冲区大小。
  # 这个参数是一个数组，包含三个值，分别表示 TCP 接收缓冲区的最小值、默认值和最大值。
  setOrReplace "net.ipv4.tcp_rmem" "8192 262144 536870912"
  # 定义接收套接字缓冲区大小的最大值(以字节为单位)。512M
  setOrReplace "net.core.rmem_max" "536870912"
  # TCP协议在发送数据时使用的缓冲区大小。
  # 这个参数是一个数组，包含三个值，分别表示 TCP 发送缓冲区的最小值、默认值和最大值。
  setOrReplace "net.ipv4.tcp_wmem" "4096 16384 536870912"
  # 定义系统中发送缓冲区的最大大小
  setOrReplace "net.core.wmem_max" "536870912"
  # 用于控制 TCP协议的窗口缩放选项，允许在高带宽和高延迟的网络环境中使用更大的接收窗口，从而提高数据传输效率。
  # 设置 TCP 窗口缩放因子的最大值。
  # 这个因子用于扩展 TCP 窗口大小，使得 TCP 可以支持超过 65,535 字节的窗口大小。
  # 窗口缩放因子是一个 0 到 14 的值，表示窗口大小的扩展倍数。
  #setOrReplace "net.ipv4.tcp_adv_win_scale" "-2"
  setOrReplace "net.ipv4.tcp_adv_win_scale" "4"
  # 控制 TCP 协议在处理接收缓冲区时的最大字节数，它与 TCP 的接收缓冲区合并（collapse）机制有关，定义了在合并过程中，允许合并的最大字节数。
  # 当 TCP 接收缓冲区中有多个小的数据包到达时，内核可能会将这些小的数据包合并成一个更大的数据包，以提高处理效率和减少上下文切换的开销。
  # Cloudflare的补丁，需要自行安装，补丁地址：https://github.com/cloudflare/linux
  #setOrReplace "net.ipv4.tcp_collapse_max_bytes" "6291456"
  # 定义了 TCP 套接字在发送缓冲区中未发送的数据的最小字节数。
  # 用于设置一个阈值，只有当发送缓冲区中的未发送数据量低于这个阈值时，TCP 才会尝试发送更多的数据。
  setOrReplace "net.ipv4.tcp_notsent_lowat" "131072"
  # 定义可用于本地 TCP 和 UDP 连接的端口范围。增大端口范围可以允许更多的并发连接。
  # 这个参数指定了系统可以分配给出站连接的端口号的最小值和最大值。默认32768 60999
  setOrReplace "net.ipv4.ip_local_port_range" "1024 65535"
  # 定义在一个监听套接字上可以排队等待接受的最大连接数
  setOrReplace "net.core.somaxconn" "32768"
  # 定义在网络设备接收队列中，允许的最大未处理数据包数量
  setOrReplace "net.core.netdev_max_backlog" "32768"
  # 用于控制 TCP TIME_WAIT 状态的最大桶数。
  # TIME_WAIT 状态是 TCP 连接关闭后的一种状态，目的是确保所有的数据包都能被正确处理，并防止旧的重复数据包干扰新的连接。
  setOrReplace "net.ipv4.tcp_max_tw_buckets" "65536"
  # 用于控制在 TCP 连接的接收队列溢出时的行为。
  # 当 TCP 连接的接收队列已满，且无法再接收新的数据包时，系统可以选择放弃（abort）该连接。
  # 具体来说，当这个参数设置为 1 时，如果 TCP 连接的接收队列溢出，内核会立即放弃该连接，而不是等待连接的另一端进行处理。
  # 这可以帮助减少资源的消耗，尤其是在高流量的网络环境中，因为它可以防止系统在处理过多的连接时变得不稳定。
  # 默认情况下，tcp_abort_on_overflow 的值通常是 0，表示在接收队列溢出时不会立即放弃连接，而是会尝试处理它。
  setOrReplace "net.ipv4.tcp_abort_on_overflow" "1"
  # 用于控制 TCP 连接在空闲一段时间后重新开始数据传输时的慢启动行为。
  # 在 TCP 协议中，慢启动是一种用于控制网络拥塞的机制。
  # 当一个 TCP 连接在空闲一段时间后重新开始传输数据时，默认情况下，TCP 会将其拥塞窗口（congestion window）重置为 1 MSS（最大报文段大小），然后逐步增加。这种行为可以帮助避免在网络恢复时造成的拥塞。
  # tcp_slow_start_after_idle 参数的作用是决定在连接空闲后是否继续使用慢启动机制。
  # 如果设置为 1（默认值），则在连接空闲后，TCP 会使用慢启动机制。
  # 如果设置为 0，则在连接空闲后，TCP 会立即使用之前的拥塞窗口大小，而不是重置为 1 MSS。
  setOrReplace "net.ipv4.tcp_slow_start_after_idle" "0"
  # 用于控制 TCP 协议中时间戳选项的使用。
  # TCP 时间戳选项是 TCP 协议的一部分，主要用于提高网络性能和可靠性，尤其是在高延迟或高带宽的网络环境中。
  # 默认情况下，tcp_timestamps 的值通常是 1，表示启用时间戳选项。如果设置为 0，则禁用时间戳选项。
  setOrReplace "net.ipv4.tcp_timestamps" "1"
  # 用于启用或禁用 TCP SYN Cookies 功能。
  # SYN Cookies 是一种防止 SYN 洪水攻击（SYN flood attack）的技术，这是一种常见的拒绝服务（DoS）攻击方式。
  # 在 TCP 连接建立过程中，客户端首先发送一个 SYN 包到服务器，服务器响应一个 SYN-ACK 包，并等待客户端的 ACK 包以完成三次握手。
  # 如果服务器在等待 ACK 的过程中接收到大量的 SYN 请求，可能会导致其资源耗尽，从而无法处理合法的连接请求。
  # 启用 SYN Cookies 后，当服务器检测到 SYN 请求过多时，它不会为每个请求分配资源，而是生成一个特殊的 SYN-ACK 包，其中包含一个加密的 cookie。
  # 只有在客户端返回正确的 ACK 包时，服务器才会为该连接分配资源。这种方式可以有效地防止 SYN 洪水攻击。
  # 如果设置为 1，则启用 SYN Cookies。
  # 如果设置为 0，则禁用 SYN Cookies（默认值通常为 0）。
  setOrReplace "net.ipv4.tcp_syncookies" "0"
  # 用于控制在 TCP 连接建立过程中，发送 SYN 包的重试次数。
  # 具体来说，它定义了在发送 SYN 包后，TCP 堆栈在未收到 SYN-ACK 响应的情况下，最多会重试多少次。
  # 默认情况下，tcp_syn_retries 的值通常为 5，如果仍然没有收到响应，则会放弃连接尝试。
  setOrReplace "net.ipv4.tcp_syn_retries" "3"
  # 用于控制在 TCP 连接建立过程中，允许的最大未处理的 SYN 请求的数量。
  # 这个参数影响的是 TCP 连接的初始阶段，即在服务器接收到 SYN 包后，尚未完成三次握手的状态。
  # 当一个 TCP 服务器接收到 SYN 请求时，它会将该请求放入一个队列中，等待处理。
  # 如果在短时间内接收到大量的 SYN 请求，且这些请求的数量超过了 tcp_max_syn_backlog 的值，额外的 SYN 请求将会被丢弃，导致客户端无法建立连接。
  # 默认情况下，tcp_max_syn_backlog 的值通常为 128，但可以根据服务器的负载和预期的连接数量进行调整。
  # 增加这个值可以帮助服务器在高流量情况下更好地处理连接请求。
  setOrReplace "net.ipv4.tcp_max_syn_backlog" "32768"
  # 用于控制 TCP 连接在发送 FIN（结束）包后，保持在 FIN_WAIT2 状态的时间。F
  # IN_WAIT2 状态是 TCP 连接关闭过程中的一个阶段，表示一方已经发送了关闭连接的请求（FIN），并在等待另一方的确认（ACK）。
  # 具体来说，tcp_fin_timeout 参数定义了在 FIN_WAIT2 状态下，连接保持的最大时间（以秒为单位）。
  # 默认情况下，这个值通常为 60 秒。这个时间段的目的是确保所有的数据包都能被正确处理，并防止旧的重复数据包干扰新的连接。
  setOrReplace "net.ipv4.tcp_fin_timeout" "15"
  # 用于控制 TCP 保活（keepalive）探测包的发送间隔时间。
  # TCP 保活机制用于检测在长时间没有数据传输的情况下，连接是否仍然有效。
  # 在发送了一个保活探测包后，系统等待的时间（以秒为单位），在此时间内如果没有收到对方的响应，系统将继续发送保活探测包。
  # 默认情况下，这个值通常为 75 秒。
  setOrReplace "net.ipv4.tcp_keepalive_intvl" "3"
  # 用于控制 TCP 保活（keepalive）机制中，连接在没有数据传输的情况下，等待多长时间后开始发送保活探测包。
  # 具体来说，tcp_keepalive_time 参数定义了在 TCP 连接空闲（没有数据传输）超过指定时间后，系统开始发送保活探测包的时间（以秒为单位）。
  # 默认情况下，这个值通常为 7200 秒（即 2 小时）。
  setOrReplace "net.ipv4.tcp_keepalive_time" "600"
  # 用于控制 TCP 保活（keepalive）机制中，在发送保活探测包后，系统最多会发送多少个探测包，以确认连接是否仍然有效。
  # 默认情况下，tcp_keepalive_probes 的值通常为 9，这意味着系统最多会发送 9 个保活探测包。
  setOrReplace "net.ipv4.tcp_keepalive_probes" "5"
  # 用于控制在 TCP 连接的初始阶段（即在发送 SYN 包后）未收到响应时，系统在放弃连接之前最多会重试的次数。
  # 默认情况下，这个值通常为 3。
  setOrReplace "net.ipv4.tcp_retries1" "3"
  # 用于控制在 TCP 连接的数据传输阶段（即在连接已经建立后）未收到确认（ACK）时，系统在放弃连接之前最多会重试的次数。
  # 默认情况下，这个值通常为 15。
  setOrReplace "net.ipv4.tcp_retries2" "5"
  # 用于控制 TCP 连接在关闭时是否保存连接的度量信息（metrics）。
  # 这些度量信息通常包括连接的 RTT（往返时间）、丢包率等，用于优化后续连接的性能。
  # 当 tcp_no_metrics_save 设置为 0（默认值）时，TCP 连接在关闭时会保存其度量信息，以便在后续连接中使用。
  # 当设置为 1 时，TCP 连接在关闭时不会保存度量信息。
  # 这可能在某些情况下是有用的，例如在高流量或不稳定的网络环境中，或者在需要快速释放资源的情况下。
  setOrReplace "net.ipv4.tcp_no_metrics_save" "1"
  # 用于控制 IP 数据包的转发功能。它决定了系统是否可以作为路由器转发接收到的 IP 数据包。
  # 当 ip_forward 设置为 1 时，系统将允许转发接收到的 IP 数据包。
  # 这通常用于将数据包从一个网络接口转发到另一个网络接口，使得系统能够充当路由器。
  setOrReplace "net.ipv4.ip_forward" "1"
  # 定义了系统范围内可以同时打开的最大文件描述符的数量。这是一个全局限制，适用于整个系统。
  # 文件描述符是一个非负整数，用于标识一个打开的文件、套接字或其他输入/输出资源。
  # 在 Linux 系统中，几乎所有的 I/O 操作都通过文件描述符进行。
  # setOrReplace "fs.file-max" "104857600"
  # 用于控制每个用户可以创建的 inotify 实例的最大数量。
  # inotify 是 Linux 提供的一种文件系统事件监视机制，允许应用程序监视文件和目录的变化（如创建、删除、修改等）。
  setOrReplace "fs.inotify.max_user_instances" "8192"
  # 定义了每个进程可以打开的最大文件描述符数量。这是一个针对单个进程的限制。
  # setOrReplace "fs.nr_open" "1048576"
  # 生效
  sysctl -p
fi
