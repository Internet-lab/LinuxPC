#!/bin/bash

############################################################
# Setup error handling

set -e # exit whan a command fails

# echo an error message for debugging before exiting
trap '[ $? == 0 ] || >&2 echo "ERROR: \"${BASH_COMMAND}\" command filed with exit code $?."' EXIT

############################################################
read -ep "Enter working directory (/tmp/liveCD/): " working_dir

if [ -z "${working_dir}" ]; then
    working_dir="/tmp/liveCD"
fi
working_dir=$(realpath ${working_dir})

############################################################
read -ep "Where would you like to save the iso file? (${working_dir}/liveCD.iso)" iso_path

if [ -z "${iso_path}" ]; then
    iso_path=${working_dir}/liveCD.iso
fi

############################################################
read -p "Enter hostname for LiveCD: " hostname

############################################################
echo Checking prerequisites

ARCH=$(uname -m)
sudo apt -y -qq install squashfs-tools xorriso casper lupin-casper 1>/dev/null 2>/dev/null
sudo apt -y -qq install grub-pc-bin grub-efi-amd64-bin mtools 1>/dev/null 2>/dev/null
sudo apt -y -qq autoremove
sudo apt clean
sudo apt-get clean

############################################################

echo Checking if UserID 999 is used

reserved_user=$(getent passwd "999" | cut -d: -f1)
if [[ ! -z ${reserved_user} ]]; then
	echo User \"${reserved_user}\" is occupying the reserved ID 999
	echo Deleting user \"${reserved_user}\"

    # Disable exit-on-error since this can be ignored
    set +e

	sudo userdel ${reserved_user}
	if [[ $? != 0 ]]; then
		echo Fails to delete user ${reserved_user}
		while :; do
			read -p "Would you like to continue anyway? [yN]" answer
			case ${answer} in
			[Yy] ) break;;
			[Nn]|"" ) exit 1;;
			esac
		done
	fi

    set -e # Re-enable exit-on-error
fi

############################################################
# Setting up variables

src_dir=${working_dir}/root                 # Source directory for LiveCD files. Files are sync with `/` prior to squashing
livecd_dir=${working_dir}/liveCD            # Directory storing LiveCD boot loaders.
excluded_list_file=${working_dir}/excluded  # Files containing a list of excluded files for rsync operation
included_list_file=${working_dir}/included  # Files containing a list of excluded files for rsync operation

FORMAT=squashfs                             # File extension for the squashed LiveCD
casper_fs=casper                            # Boot loader

# Create working directory
mkdir -p "${src_dir}" ${livecd_dir}/{${casper_fs},boot/grub}

############################################################
echo Creating Excluded List

# Set excluded list to ignore non-file paths, like mounting points, device directories, etc.
# Also excludes this script and files that will change when the script is running, e.g., bash history.
cat > ${included_list_file} <<EOF
/boot/grub/
# To sync boot options, uncomment the following line
# /boot/grub/grub.cfg
/home/*
/home/*/.*
/home/*/.*/**
/home/*/Desktop
/home/*/Downloads
/home/*/Pictures
/home/*/Templates
/home/*/Videos
/home/*/Documents
/home/*/Music
/home/*/Public
EOF
cat > ${excluded_list_file} <<EOF
/boot/**
/dev/**
/etc/fstab
/etc/mtab
# DNS server setting
/etc/resolv.conf
/etc/timezone
/etc/gdm/custom.conf
/etc/X11/xorg.conf*
/home/*/**
/lost+found*
/media/*
/mnt/*
/proc/*
/root/*
/swap.img
/sys/*
/tmp/*
/var/mail*
/var/spool*
/var/tmp/*
/var/crash/*
/var/tmp/*
/var/log/*
$(realpath $0)
$(realpath ${HOME}/.bash_history)
$(realpath ${working_dir})
$(realpath ${iso_path})
$(realpath ${src_dir})
EOF
# Maybe login screen?
# /etc/lightdm/lightdm.conf
# swapfile*

############################################################
echo Creating source directory

# Copy everything to source directory
sudo rsync -ax --delete --delete-excluded --info=progress2 --include-from="${included_list_file}" --exclude-from="${excluded_list_file}" "/" "${src_dir}"

# Remove bash history 
sudo rm -f "${src_dir}/home/*/.bash_history"

############################################################
echo Configuring Casper

casp_conf=${src_dir}/etc/casper.conf
sudo sed 's/^export HOST=.*/export HOST="'"$hostname"'"/g' -i "${casp_conf}"
sudo sed 's/^# export FLAVOUR.*/export FLAVOUR="ubuntu"/g' -i "${casp_conf}"

############################################################
echo Setting hostname

hostname_file=${src_dir}/etc/hostname
echo "${hostname}" | sudo tee >/dev/null "${hostname_file}"

############################################################
export KERNEL_VER=`uname -r`
if [[ -z ${KERNEL_VER} ]]; then
    >&2 echo Cannot ascertain kernel version
    exit 1
fi

echo Copying kernel: ${KERNEL_VER}
sudo cp -p /boot/vmlinuz-${KERNEL_VER} ${livecd_dir}/${casper_fs}/
sudo cp -p /boot/initrd.img-${KERNEL_VER} ${livecd_dir}/${casper_fs}/

############################################################
# We need to update initial ram disk for changes to casper and hostname to take effect

# Mount virtual file systems for chroot
sudo mount --bind /dev/ ${src_dir}/dev
sudo mount -t proc proc ${src_dir}/proc
sudo mount -t sysfs sysfs ${src_dir}/sys
sudo mount -o bind /run ${src_dir}/run
sudo mount -o bind ${livecd_dir}/${casper_fs} ${src_dir}/boot

# May take some time for mounts to appear
sleep 1

# (chroot)
cat <<EOF | sudo chroot ${src_dir} /bin/bash
update-initramfs -u -k ${KERNEL_VER} # update initrd
EOF

# Unmount virtual file systems
sudo umount ${src_dir}/{proc,sys,dev,run,boot}

############################################################
echo Renaming kernel and initial ramdisk files

sudo mv "${livecd_dir}/${casper_fs}/vmlinuz-${KERNEL_VER}" "${livecd_dir}/${casper_fs}/vmlinuz"
sudo mv "${livecd_dir}/${casper_fs}/initrd.img-${KERNEL_VER}" "${livecd_dir}/${casper_fs}/initrd"

############################################################
echo Squashing source directory ${src_dir}

rm -f "${livecd_dir}/${casper_fs}/filesystem.${FORMAT}"
sudo mksquashfs "${src_dir}" "${livecd_dir}/${casper_fs}/filesystem.${FORMAT}" -noappend
# Add size information for the file system
echo -n $(sudo du -s --block-size=1 ${src_dir} | tail -1 | awk '{print $1}') > ${livecd_dir}/${casper_fs}/filesystem.size

############################################################
echo Computing checksum
find ${livecd_dir} -type f -print0 | xargs -0 sudo md5sum | sed "s@${livecd_dir}@.@" | grep -v md5sum.txt > ${livecd_dir}/md5sum.txt

# create grub configuration
grub_config_file="${livecd_dir}/boot/grub/grub.cfg"
cat <<EOF | sudo tee >/dev/null "${grub_config_file}"
set default="0"
set timeout=3

menuentry "LiveCD Default" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 quiet noprompt fsck.mode=skip
initrd /casper/initrd
}

menuentry "LiveCD safe mode" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 quiet noprompt xforcevesa
initrd /casper/initrd
}
menuentry "LiveCD CLI" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 quiet noprompt fsck.mode=skip textonly
initrd /casper/initrd
}
menuentry "LiveCD load in RAM" {
linux /casper/vmlinuz boot=casper toram quiet noprompt fsck.mode=skip
initrd /casper/initrd
}
EOF

############################################################
echo Creating ISO file

rm -f "${iso_path}"
sudo grub-mkrescue -o "${iso_path}" ${livecd_dir}

echo The ISO is created at ${iso_path}
