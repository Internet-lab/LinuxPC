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

# Write the ISO to the disk
sudo dd if="${iso_src}" of="${disk}" bs=4M status=progress oflag=sync

echo Done
