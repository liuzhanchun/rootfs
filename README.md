# rootfs
Linux最小根文件系统

git clone 克隆之后创建设备文件
#cd rootfs/dev
#mknod -m 666 console c 5 1
#mknod -m 666 null c 1 3

固化到sd卡
查看/dev下的描述文件符  一般为/dev/sdb
sudo fdisk -l  
执行如下脚本（注 遇到错误需要执行两遍）
sudo ./mksdboot.sh --device /dev/sdb

固化sd卡系统到emmc
从sd卡启动
/opt/tools目录下执行
./mkemmc-boot.sh --device /dev/mmcblk1
