#!/bin/bash
# create bootable disk
read -ep "Please enter the path to the disk (USB) device (e.g., /dev/sdg): " disk
# make sure no partition was entered
x=`echo ${disk} | cut -d'/' -f 2`
y=`echo ${disk} | cut -d'/' -f3`
y=`echo ${y:0:3}`
disk=`echo "/$x/$y"`

if [ ! -e "${disk}" ]; then
    echo "Cannot find disk ${disk}. Exiting"
    exit 1
fi

while :; do
	read -p "Disk ${disk} was selected. Continue? [yn] " answer
	case ${answer} in
	[Yy]* ) break;;
	[Nn]* ) exit 1;;
	* ) ;;
	esac
done

############################################################

while :; do
    read -ep "Please enter the path to the ISO file: (default: /tmp/liveCD/liveCD.iso) " iso_src
    iso_src="${iso_src/#\~/$HOME}"

    if [ -z "${iso_src}" ]; then
        iso_src="/tmp/liveCD/liveCD.iso"
    fi

    if [ ! -f "${iso_src}" ]; then
        echo "Cannot find an ISO file at ${iso_src}."
    else
        break
    fi
done

############################################################
read -ep "Please enter name for the new partition: (default: LAB_LIVE_DISK) " partition_name

if [ -z "${partition_name}" ]; then
    partition_name="LAB_LIVE_DISK"
fi

############################################################
echo "Formatting ${disk}"

while :; do
	X=`df | grep "$disk" | awk '{print $NF}'`
	if [ ! -z "${X}" ]; then
		echo "Unmounting disk at ${X}.."
		sudo umount "${X}"
		if [[ $? != 0 ]]; then
			echo "an error occured when unmounting"
			exit 1
		fi
	else
		break
	fi
done

# Wipe the disk clean
sudo wipefs -a "${disk}"
# Partition the disk with MSDOS partition table
sudo parted "${disk}" mklabel msdos
# Create FAT32 partition starting at 1024-bytes, and ends at the end of the disk (100%)
# The first 512B are reserved for GRUB, the rest are for alignment
sudo parted "${disk}" mkpart primary fat32 1M 100% -a optimal

# May take some time for the partition to appear
sleep 3
# Create MSDOS file system named "{partition_name}"
sudo mkfs.vfat -n "${partition_name}" "${disk}1"

############################################################
echo "Installing GRUB"

mount_point=/tmp/liveCD/mnt/
mkdir -p ${mount_point}
sudo mount "${disk}1" "${mount_point}"

echo sudo grub-install --no-floppy --force --root-directory="${mount_point}" "${disk}"
sudo grub-install --no-floppy --force --root-directory="${mount_point}" "${disk}"

############################################################
echo Getting UUID and Label for the disk

for each in `sudo blkid "${disk}1"`;do
	case "$each" in
	"UUID="*)
		[ "$each" != *"PARTUUID"* ] && UUID=`echo "$each" | grep "UUID" | cut -d'=' -f2 |xargs`;;
	*"LABEL="*)
		LABEL=`echo "$each" | grep "LABEL" | cut -d'=' -f2 |xargs`;;
	*"TYPE="*)
		TYPE=`echo "$each" | grep "TYPE" | cut -d'=' -f2 |xargs`;;
	*"PARTUUID="*)
		PARTUUID=`echo "$each" | grep "PARTUUID=" | cut -d'=' -f2 |xargs`;;
	*)
		continue;;
	esac
done

############################################################
echo Writing GRUB configuration

iso_dst=/root.iso
cat <<EOF | sudo tee >/dev/null ${mount_point}/boot/grub/grub.cfg
set default="0"
set timeout=0

loopback loop ${iso_dst}
set root=(loop)

menuentry "Boot LIVE CD from HDD/USB" {
linux /casper/vmlinuz boot=casper iso-scan/filename=${iso_dst} net.ifnames=0 biosdevname=0 noprompt
initrd /casper/initrd
}
EOF

############################################################
echo "Copying the LiveCD to the USB drive.."

sudo cp "${iso_src}" "${mount_point}/${iso_dst}"

############################################################

sudo umount ${mount_point}
echo Done
