#!/bin/bash
Green="\033[32m"
Font="\033[0m"
Red="\033[31m"

# 设置ipv6
read -p "Do you wish to setting ipv6? (Y/N):" yn
case "$yn" in
"Yy")
  cat >>/etc/network/interfaces <<EOF
iface eth0 inet6 static
        address $1
        netmask 48
        gateway 2605:6400:20::1
EOF
  echo -e "设置ipv6地址为：$1"
  ;;
"Nn")
  echo "Cancel setting ipv6"
  ;;
esac

# 添加swap
read -p "Do you wish to add swap? (Y/N):" yn
case "$yn" in
"Yy")
  re='^[0-9]+$'
  if ! [[ $2 =~ $re ]]; then
    echo "Swap Size has to be an integer"
    exit 1
  fi
  swapsize=$2
  #检查是否存在swapfile
  grep -q "swapfile" /etc/fstab
  #如果不存在将为其创建swap
  if [ $? -ne 0 ]; then
    echo -e "${Green}swapfile未发现，正在为其创建swapfile${Font}"
    fallocate -l ${swapsize}M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' >>/etc/fstab
    echo -e "${Green}swap创建成功，并查看信息：${Font}"
    cat /proc/swaps
    cat /proc/meminfo | grep Swap
  else
    echo -e "${Red}swapfile已存在，swap设置失败，请先运行脚本删除swap后重新设置！${Font}"
  fi
  # 修改swappiness
  sysctl -w vm.swappiness=60
  ;;
"Nn")
  echo "Cancel add swap"
  ;;
esac

# 挂载存储块
read -p "Do you wish to setting disk? (Y/N):" yn
case "$yn" in
"Yy")
  disk_id=$(ls /dev/disk/by-id/ | grep scsi)
  echo -e "发现存储块：$disk_id"
  # 格式化存储块
  mkfs.ext4 -F /dev/disk/by-id/"$disk_id"
  # 创建并挂载目录
  mkdir -p /pt && chmod -R 777 /pt/
  mount -o discard,defaults /dev/disk/by-id/"$disk_id" /pt
  # 设置开机自动挂载
  echo "/dev/disk/by-id/$disk_id /pt ext4 defaults 0 0" >>/etc/fstab
  ;;
"Nn")
  echo "Cancel setting disk"
  ;;
esac

# 设置时区
timedatectl set-timezone Asia/Shanghai

# 安装网络监控
apt install sysstat vnstat -y

# 安装常用软件
apt install curl vim -y

#修改qb配置
systemctl status qbittorrent-nox@admin
wget https://raw.githubusercontent.com/leyung/shell/main/buyvm/qBittorrent.conf -O /home/admin/.config/qBittorrent/qBittorrent.conf
chown admin /home/admin/.config/qBittorrent
systemctl start qbittorrent-nox@admin
