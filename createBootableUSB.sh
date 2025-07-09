#!/bin/bash

############################################################
# Setup error handling

# exit whan a command fails
set -e

# echo an error message for debugging before exiting
trap '[ $? == 0 ] || >&2 echo "ERROR: \"${BASH_COMMAND}\" command filed with exit code $?."' EXIT

############################################################
arch=$(dpkg --print-architecture)

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
read -ep "Please enter the name for the new partition: (default: LAB_LIVE_DISK) " partition_name

if [ -z "${partition_name}" ]; then
    partition_name="LAB_LIVE_DISK"
fi

############################################################

while :; do
	X=`df | grep "$disk" | awk 'BEGIN { ORS=" " }; {print $1F}'`
	if [ ! -z "${X}" ]; then
		echo "Unmounting ${X}"
		sudo umount ${X}
		if [[ $? != 0 ]]; then
			echo "an error occured when unmounting"
			exit 1
		fi
	else
		break
	fi
done

echo "Formatting ${disk}"
# Wipe the disk clean
sudo wipefs -a "${disk}"
# Partition the disk with GUID partition table
sudo parted "${disk}" mklabel gpt
# Partition 1
sudo parted "${disk}" mkpart '"BIOS boot partition"' fat32 1MiB 2MiB
sudo parted "${disk}" set 1 bios_grub on
# Partition 2
sudo parted "${disk}" mkpart '"EFI system partition"' fat32 2MiB 1026MiB
sudo parted "${disk}" set 2 esp on
# Partition 3
sudo parted "${disk}" mkpart '"root partition"' fat32 1026MiB 100%

sleep 3 # May take some time for the partitions to appear

sudo mkfs.fat -F 32 "${disk}2"
sudo mkfs.ext4 -F "${disk}3"

############################################################
echo "Installing GRUB"

root_mnt=/tmp/liveCD/mnt/root
efi_mnt=/tmp/liveCD/mnt/efi
mkdir -p ${root_mnt} ${efi_mnt} 
sudo mount "${disk}3" "${root_mnt}"
sudo mount "${disk}2" "${efi_mnt}"

sudo grub-install --target=x86_64-efi --efi-directory="${efi_mnt}" --removable -s --no-floppy --force --root-directory="${root_mnt}" "${disk}"
sudo grub-install --target=i386-pc --removable -s --no-floppy --force --root-directory="${root_mnt}" "${disk}"

############################################################
echo Writing GRUB configuration

iso_dst=/root.iso
cat <<EOF | sudo tee >/dev/null ${root_mnt}/boot/grub/grub.cfg
set default="0"
set timeout=0

loopback loop ${iso_dst}
set root=(loop)

menuentry "Boot LIVE CD from HDD/USB" {
linux /casper/vmlinuz boot=casper net.ifnames=0 biosdevname=0 noprompt
initrd /casper/initrd
}
EOF

############################################################
echo "Copying the LiveCD to the USB drive.."

sudo cp "${iso_src}" "${root_mnt}/${iso_dst}"

############################################################

sudo umount "${root_mnt}" "${efi_mnt}"
echo Done
