#!/bin/bash

############################################################
echo Checking prerequisites

required_packages="squashfs-tools xorriso casper lupin-casper"
missing_packages=
for package in ${required_packages}; do
	if ! dpkg -s ${package} 1>/dev/null 2>&1; then
		missing_packages+="${package} "
	fi
done
if [ ! -z "${missing_packages}" ]; then
	echo "Installing missing package ${missing_packages}"
	sudo apt -y install ${missing_packages}
	if [[ $? != 0 ]]; then
		echo "Failed to install missing packages" >&2
		exit 1;
	fi
fi

############################################################
save_file=".makeLiveCD.env"
echo Looking for environment file ${save_file}

if test -f ${save_file}; then
	while :; do
		echo "Found an environment file ${save_file}".
		read -p "Would you like to load it? [Yn] " answer
		case ${answer} in
			[YNyn]*|"" )
				break;;
		esac
	done
else
	echo "No environment file found."
	answer=n
fi
if [[ ${answer} == @([Yy]*|) ]]; then
	source ${save_file}
	if [[ $? != 0 ]]; then
		echo "Failed to import environment file"
	else
		echo Loaded ${save_file}
		imported_save_file=y
	fi
fi

############################################################
echo Setting up working directory

if [ -z "${working_dir}" ]; then
	read -p "Enter working directory (/tmp/liveCD/): " working_dir
	if [ -z "${working_dir}" ]; then
		working_dir="/tmp/liveCD"
	fi
fi
working_dir=$(realpath ${working_dir})
echo ${working_dir}

############################################################

if [ -z "${iso_path}" ]; then
	read -p "Where would you like to save the iso file? (${working_dir}/liveCD.iso)" iso_path
	if [ -z "${iso_path}" ]; then
		iso_path=${working_dir}/liveCD.iso
	fi
fi

############################################################
if [ -z "${hostname}" ]; then
	read -p "Enter hostname for LiveCD: " hostname
fi

############################################################

echo Checking if UserID 999 is used

reserved_user=$(getent passwd "999" | cut -d: -f1)
if [[ ! -z ${reserved_user} ]]; then
	echo User \"${reserved_user}\" is occupying the reserved ID 999
	echo Deleting user \"${reserved_user}\"
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
fi

############################################################

if [[ ${imported_save_file} != y ]]; then
	while :; do
		read -p "Would you like to save your answers to a save file ${save_file}? [Yn]" answer
		case ${answer} in
			[Yy]|"" )
				echo "Saving data"
				cat > ${save_file} <<-EOF
					hostname=${hostname}
					working_dir=${working_dir}
					iso_path=${iso_path}
					EOF
				break;;
			[Nn] ) break;;
		esac
	done
fi

############################################################
# Setting up variables

src_dir=${working_dir}/rootfs							# Source directory for LiveCD files. Files are sync with `/` prior to squashing
livecd_dir=${working_dir}/liveCD					 # Directory storing LiveCD boot loaders.
excluded_list_file=${working_dir}/excluded # Files containing a list of excluded files for rsync operation

FORMAT=squashfs														# File extension for the squashed LiveCD
casper_fs=casper													 # Boot loader

# Create working directory
mkdir -p "${src_dir}" ${livecd_dir}/{${casper_fs},boot/grub}
if [[ $? != 0 ]]; then
	echo "Fails to create ${src_dir} or ${livecd_dir}"
	exit 1
fi

############################################################
echo Cleaning up some space

sudo apt clean

############################################################
echo Creating Excluded List

# Set excluded list to ignore non-file paths, like mounting points, device directories, etc.
# Also excludes this script and files that will change when the script is running, e.g., bash history.
cat > ${excluded_list_file} <<EOF 
/boot/grub/*
/dev/*
/etc/fstab
/etc/mtab
/etc/timezone
/etc/gdm/custom.conf
/etc/X11/xorg.conf*
/lost+found*
/media/*
/mnt/*
/proc/*
/root/*
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
EOF
# Maybe login screen?
# /etc/lightdm/lightdm.conf
# swapfile*

############################################################
echo Creating source directory

# Create source directory, and add them to excluded list
mkdir -p ${src_dir}
echo "${src_dir}" >> ${excluded_list_file}
# Copy everything to source directory
sudo rsync -a --info=progress2 --exclude-from="${excluded_list_file}" --one-file-system "/" "${src_dir}" --delete || ( echo "An error occured during rsync!"; exit 1; )
# To include boot options, uncomment the following line
# sudo rsync -a --info-progress2 /boot/grub/grub.cfg "${src_dir}/boot/grub/grub.cfg"

############################################################
echo Configuring Casper

casp_conf=${src_dir}/etc/casper.conf
sudo sed 's/^export HOST=.*/export HOST="'"$hostname"'"/g' -i "${casp_conf}"
sudo sed 's/^# export FLAVOUR.*/export FLAVOUR=""/g' -i "${casp_conf}"

############################################################
echo Resetting DNS server setting
sudo rm -f ${src_dir}/etc/resolv.conf

############################################################
echo Setting hostname

hostname_file=${src_dir}/etc/hostname
echo "${hostname}" | sudo tee >/dev/null "${hostname_file}"

############################################################
echo Squashing source directory ${src_dir}

rm -f "${livecd_dir}/${casper_fs}/filesystem.${FORMAT}"
sudo mksquashfs "${src_dir}" "${livecd_dir}/${casper_fs}/filesystem.${FORMAT}" -noappend
# add fs size information
echo -n $(sudo du -s --block-size=1 ${src_dir} | tail -1 | awk '{print $1}') > ${livecd_dir}/${casper_fs}/filesystem.size

############################################################
export KERNEL_VER=`cd /boot && ls -1 vmlinuz-* | tail -1 |sed 's@vmlinuz-@@'`
if [[ -z ${KERNEL_VER} ]]; then
	echo Cannot ascertain kernel version
	exit 1
fi

echo Copying kernel: ${KERNEL_VER}

sudo cp -p /boot/vmlinuz-${KERNEL_VER} ${livecd_dir}/${casper_fs}/vmlinuz
sudo cp -p /boot/initrd.img-${KERNEL_VER} ${livecd_dir}/${casper_fs}/initrd
# sudo cp -p /boot/memtest86+.bin ${livecd_dir}/boot/

############################################################
echo Computing checksum
find ${livecd_dir} -type f -print0 | xargs -0 sudo md5sum | sed "s@${livecd_dir}@.@" | grep -v md5sum.txt > ${livecd_dir}/md5sum.txt

# create grub configuration
grub_config_file="${livecd_dir}/boot/grub/grub.cfg"
cat <<EOF | sudo tee >/dev/null "${grub_config_file}"
set default="0"
set timeout=10

menuentry "LiveCD Default" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 quiet splash
initrd /casper/initrd
}

menuentry "LiveCD safe mode" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 xforcevesa quiet splash
initrd /casper/initrd
}
menuentry "LiveCD CLI" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 textonly quiet splash
initrd /casper/initrd
}
menuentry "LiveCD persistent mode" {
linux /casper/vmlinuz boot=casper ro net.ifnames=0 biosdevname=0 persistent quiet splash
initrd /casper/initrd
}
menuentry "LiveCD load in RAM" {
linux /casper/vmlinuz boot=casper toram quiet splash
initrd /casper/initrd
}
EOF

############################################################
echo Creating ISO file
rm -f "${iso_path}"
sudo grub-mkrescue -o "${iso_path}" ${livecd_dir}

echo The ISO is created at ${iso_path}

