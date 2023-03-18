#!/bin/bash
Green="\033[32m"
Font="\033[0m"
Red="\033[31m"
# 设置ipv6
cat >> /etc/network/interfaces <<EOF
iface eth0 inet6 static
        address $1
        netmask 48
        gateway 2605:6400:30::1
EOF
echo -e "设置ipv6地址为：$1"

# 添加swap
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
	echo '/swapfile none swap defaults 0 0' >> /etc/fstab
  echo -e "${Green}swap创建成功，并查看信息：${Font}"
  cat /proc/swaps
  cat /proc/meminfo | grep Swap
else
	echo -e "${Red}swapfile已存在，swap设置失败，请先运行脚本删除swap后重新设置！${Font}"
fi
# 修改swappiness
sysctl -w vm.swappiness=60

# 挂载存储块
disk_id=`ls /dev/disk/by-id/ | grep scsi`
echo -e "发现存储块：$disk_id"
# 格式化存储块
mkfs.ext4 -F /dev/disk/by-id/$disk_id
# 创建并挂载目录
mkdir -p /pt && chmod -R 777 /pt/
mount -o discard,defaults /dev/disk/by-id/$disk_id /pt

# 设置开机自动挂载
echo "/dev/disk/by-id/$disk_id /pt ext4 defaults 0 0" >> /etc/fstab

# 设置时区
timedatectl set-timezone Asia/Shanghai

# 安装网络监控
apt install sysstat vnstat -y