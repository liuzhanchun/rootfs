#! /bin/sh

VERSION="1.0"

execute ()
{
    $* >/dev/null
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: executing $*"
        echo
        exit 1
    fi
}

version ()
{
  echo
  echo "`basename $1` version $VERSION"
  echo "Script to create bootable SD card for Am572x kits"
  echo

  exit 0
}

usage ()
{
  echo "
Usage: `basename $1` [options] <device>

Mandatory options:
  --device              SD block device node (e.g /dev/mmcblk1)

Optional options:
  --version             Print version.
  --help                Print this help message.
"
  exit 1
}

# Process command line...
while [ $# -gt 0 ]; do
  case $1 in
    --help | -h)
      usage $0
      ;;
    --device | -d) shift; device=$1; shift; ;;
    --version) version $0;;
    *) copy="$copy $1"; shift; ;;
  esac
done

#test -z $sdkdir && sdkdir=pwd/image
test -z $device && usage $0
sdkdir=$PWD

if [ ! -d $sdkdir ]; then
   echo "ERROR: $sdkdir does not exist"
   exit 1;
fi

if [ ! -b $device ]; then
   echo "ERROR: $device is not a block device file"
   exit 1;
fi
echo "* Press <ENTER> to confirm.... *"
read junk

for i in `ls -1 ${device}p?`; do
 echo "unmounting device '$i'"
 umount $i 2>/dev/null
done

execute "dd if=/dev/zero of=$device bs=1024 count=1024"

SIZE=`fdisk -l $device | grep Disk | awk '{print $5}'`
echo DISK SIZE - $SIZE bytes

parted -s ${device} mklabel msdos
parted -s ${device} unit cyl mkpart primary fat32 -- 0 5 #boot
parted -s ${device} set 1 boot on
parted -s ${device} unit cyl mkpart primary ext2 -- 5 50 #rootfs
parted -s ${device} unit cyl mkpart primary ext2 -- 50 100 #fpga dsp
parted -s ${device} unit cyl mkpart primary ext2 -- 200 -2  # userdata
msleep 500

for i in `ls -1 ${device}p?`; do
 echo "unmounting device '$i'"
 umount $i 2>/dev/null
done

echo "Formating ${device}p1 ..."
mkfs.vfat -F 32 -n "boot" ${device}p1
echo "Formating ${device}p2 ..."
mkfs.ext4 -L "rootfs" ${device}p2
echo "Formating ${device}p3 ..."
mkfs.ext4 -L "dspfpga" ${device}p3
echo "Formating ${device}p4 ..."
mkfs.ext4 -L "userdata" ${device}p4
sync
sleep 1

mount ${device}p1 /run/media/mmcblk1p1
mount ${device}p2 /run/media/mmcblk1p2
mount ${device}p3 /run/media/mmcblk1p3
mount ${device}p4 /run/media/mmcblk1p4
sync

echo "Copying MLO/u-boot.img to ${device}p1"
mkdir -p /tmp/sdk/$$
mount ${device}p1 /tmp/sdk/$$
cp -rf /run/media/mmcblk0p1/* /tmp/sdk/$$/
echo "Copy MLO/u-boot.img to ${device}p1 Finished!"
sync

umount /tmp/sdk/$$
rm -rf /tmp/sdk/$$

echo "Copying filesystem to ${device}p2 ..."
#cp -rf /run/media/mmcblk0p3/* /run/media/mmcblk1p2/
echo "Copy filesystem to ${device}p2 Finished!"
echo "syncing .........."
echo
sync

for i in `ls -1 ${device}p?`; do
 echo "unmounting device '$i'"
 umount $i 2>/dev/null
done

echo
echo

echo "completed!"

