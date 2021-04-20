# LinuxPC

The available scripts install a Live CD version of the Linux PC for the Internet Lab on a "baremetal" PC system.  
The process described here assumes that the installation is done in Virtualbox on a Mac or Windows or Linux system (The scripts also run on a native Linux installation).

Version:  April 2021
## 1. Install Ubuntu server 
a. Download Ubuntu Server 20.04 LTS from 
https://ubuntu.com/download/server

b. Install the Ubuntu server as a VM in Virtualbox (the development was done with Virtualbox 6.1). Allocate min. 2048 MB memory and min. 20 GB for the virtual disk.
During the installation, use the default settings. 

 * For the user name password, select **Name: `Labuser`, username: `labuser`, password: `labuser`**.
 * Agree to the installation of OpenSSH server

## 2. Install software on Ubuntu server
a. Start the Ubuntu server in Virtualbox and log in as `labuser`. 
b. From the home directory of `labuser` download the script "InstallBaremetalPC.sh" using the command 

```$ wget  https://raw.githubusercontent.com/Internet-lab/LinuxPC/main/InstallBaremetalPC.sh```

c. Execute the script with the command 

```$ sudo bash InstallBaremetalPC.sh```

 - The script installs  software packages and sets configuration files needed in the Internet Lab (as well as some additional software). 
 - Answer `Y` when  prompted and select `<Yes>` in the screen `Configuring wireshark-common`. 
 - The script also downloads the shell scripts `makeLiveCD.sh` and `createBootableUSB.sh` used for the creation of the LiveCD.
 - The script reboots the OS, when the system reboots it will show a login screen of the Gnome Desktop. Login as `labuser` and verify that the software installation is completed. 

## 3. Create an ISO LiveCD image
The next step creates a LiveCD ISO image, which has the same configurationas the customized Ubuntu server. 

### 3.1  **(Optional)** Avoid increasing the size of VM when creating a new LiveCD.

The  creation of a  LiveCD from a VM   expands the size of the virtual machine substantially. The reason is that for the creation of the ISO image, large parts of the Master VM are copied in a temporary directory. For this, the virtual disk of the Master VM is dynamically increased. To avoid increasing the size of the original VM of the Ubuntu server from Step 2 (*Install software on Ubuntu server*), create a copy of  VM. We call the original VM the *Master VM* and the copied VM the *Build VM*. 
Proceed as follows: 
 - After making changes to the VM  (running InstallBaremetalPC.sh or installing/removing packages), export the VM using “Export Appliance” in Virtualbox. The exported appliance is saved as an OVF file. 
 - Import the exported appliance to create a new VM. We call this version the *Build VM*. 
 - Start the *Build VM* and log in as `labuser'.
 - Next run the scripts to create an ISO LiveCD image and burn the ISO file to a flashdrive. Once the flashdrive is created, delete the *Build VM*.   

### 3.2  Run script that creates ISO image 
The shelll script `makeLiveCD.sh` creates an .iso image (“root.iso”) from the current virtual machine. 
From the home directory of `labuser`, run the script with the command 

```$ sudo bash makeLiveCD.sh```

The script asks a few times for information. If you do not know otherwise, select the default option.  The default location of the ISO script is `/tmp/tmpfs/liveCD.iso`. 

## 4. Create a bootable flashdrive with LiveCD 
a.  Insert a flashdrive (min. 16 GB) into a USB port of the computer where Virtual with the VM from Step 3 is running. The flashdrive must be mounted in the Ubuntu VM. 
Sometimes the Ubuntu VM is unable to grab the flashdrive, i.e., it does not appear as a drive. In this case, select the Ubuntu VM in the VM Manager and go to Settings→ Ports → USB, and add the flashdrive. Then removing and re-inserting the flashdrive should show it in the Ubuntu VM. 

b. Identify the device name of the flashdrive with the command 

```$ sudo lsblk -p```

Typically, the device name is /dev/sdb with one partition /dev/sdb1 (It can be /dev/sdc or /dev/sdc1). 

c. From the home directory of `labuser`, run the script with the command 

```$ sudo bash createBootableUSB.sh```

The script will prompt for hardware specific information. In particular, the script requests to enter the device name of the flashdrive (`/dev/sdb`).
Once the script is completed, remove the flashdrive.  The flashdrive contains  the ISO image (`root.iso`) and grub configuration files.

## 5. Copying the LiveCD to the hard drive 
The LiveCD can be run on a target machine from the flashdrive. This assumes that the BIOS is set so that the system first tries to boot from a flashdrive. 


>**Note: Copying the LiveCD to the hard drive will delete all partitions on the hard disk. All data on the hard disk will be lost.**

a. Insert the flashdrive from Step 4 into the target system. Rebooting the target system starts  the LiveCD. Log in as `labuser`.

b. Identify the device names of the flashdrive and the hard disk on the target system.  

```$ sudo lsblk -p```

In many cases the hard disk is `/dev/sda` and the inserted flashdrive is `/dev/sdb`. Verify that this is the case. Otherwise, take not of the device names.  

c. Make sure that the storage capacity of the hard disk is as least that of the flashdrive.  Then, assuming that `/dev/sdb is the flashdrive and `/dev/sda` is the hard disk, copy the flashdrive to the hard disk with the command 

```$ sudo dd if=/dev/sdb of=/dev/sda```

The command  take considerable time to complete. 

d. Remove the flashdrive and reboot the target machine. 

