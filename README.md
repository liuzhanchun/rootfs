# rootfs
Linux最小根文件系统

git clone 克隆之后创建设备文件
#cd rootfs/dev
#mknod -m 666 console c 5 1
#mknod -m 666 null c 1 3
