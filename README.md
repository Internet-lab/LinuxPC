# LinuxPC

The available scripts install a Live CD version of the Linux PC for the Internet Lab on a "baremetal" PC system.  
The process described here assumes that the installation is done in Virtualbox on a Mac or Windows or Linux system (The scripts also run on a native Linux installation).

Version:  April 2021
## 1. Install Ubuntu server 
For installing Ubuntu server in Virtualbox, there are excellent instructions available at https://hibbard.eu/install-ubuntu-virtual-box/ . Follow the instructions until you get to *"Up and Running with SSH"*. 

Consider the following points during the installation:

 a. Download Ubuntu Server 20.04 LTS from https://ubuntu.com/download/server

 b. Create a new VM. If you start the name with "Ubu", Virtualbox automatically selects *Ubuntu (64-bit)*. Go to `Settings→Ports→USB` and select `USB 3.0 Controller`. 

 c. Install the Ubuntu server from the downloaded .iso file as a VM in Virtualbox (the development was done with Virtualbox 6.1). Allocate min. 2048 MB memory and min. 20 GB for the virtual disk.

 During the installation, use the default settings. 

 * For the user name password, select **Name: `Labuser`, username: `labuser`, password: `labuser`**.
 * Agree to the installation of OpenSSH server
 * Once the installation is complete, Ubuntu often does not reboot. In this case, force a shut down from Virtualbox. 
 * In Virtualbox, check that the (virtual) optical drive containing the .iso file is removed. If not, remove it.   

## 2. Install software on Ubuntu server
a. Start the Ubuntu server in Virtualbox and log in as `labuser`. 

b. From the home directory of `labuser` download the script *InstallBaremetalPC.sh* using the command 

```
$ wget  https://raw.githubusercontent.com/Internet-lab/LinuxPC/main/InstallBaremetalPC.sh
```

c. Execute the script with the command 

```
$ sudo bash InstallBaremetalPC.sh
```

 - The script installs  software packages and sets configuration files needed in the Internet Lab (as well as some additional software). 
 - Answer `Y` when  prompted and select `<Yes>` in the screen `Configuring wireshark-common`. 
 - The script also downloads the shell scripts `makeLiveCD.sh` and `createBootableUSB.sh` used for the creation of the LiveCD.
 - The script reboots the OS, when the system reboots it will show a login screen of the Gnome Desktop. Login as `labuser` and verify that the software installation is completed. 

d. Touch up the VM 
  - If not already logged in, start the (Build) VM and log in as `labuser`.
  - Change the screen background. There are templates available for PC1, PC2, ...
  - In the *Activities*, remove the icon for `Help` and add icons for `Wireshark`, `Screenshot`, `LXTerminal`, `Files`,  and `Mousepad`.
  - Change the power saving mode to prevent that the system locks  the screen after an idle period or suspends. In the Ubuntu desktop go to `Settings→ Ports`. In *Power Saving*, select **Never**. In *Suspend & Power Button*, set *Automatic Suspend* to **Off**.
  - In the file `/usr/share/applications/wireshark.desktop`, change the line `Exec=wireshark %f` to *`Exec=sudo wireshark %f`*. 
  - We want to make sure that the following services are not started at boot time: 
  
            avahi-daemon   named  bgpd   ospfd   ospf6d  pimd   ripd   ripngd   isisd   zebra 
       
    To do this we should disable them with the commands 
    ```
    $ sudo systemctl disable avahi-daemon
    $ sudo systemctl disable named
    $ sudo systemctl disable bgpd
    $ sudo systemctl disable ospfd
    $ sudo systemctl disable ospf6d
    $ sudo systemctl disable pimd
    $ sudo systemctl disable ripd
    $ sudo systemctl disable rpingd
    $ sudo systemctl disable isisd    
    $ sudo systemctl disable zebra
    ```
    In addition, we need to edit the service files for all of the above services and comment out a line. In each of the following files, go to the *Install* section of the files and put a `#` in front of `Wanted by`: 
    ```
    /lib/systemd/system/avahi-daemon.service    
    /lib/systemd/system/named.service
    /lib/systemd/system/bgpd.service
    /lib/systemd/system/ospfd.service
    /lib/systemd/system/ospf6d.service
    /lib/systemd/system/pimd.service
    /lib/systemd/system/ripd.service
    /lib/systemd/system/ripngd.service
    /lib/systemd/system/isisd.service
    /lib/systemd/system/zebra.service  
    ```
    
## 3. Create an ISO LiveCD image
The following instructions create a LiveCD ISO image, which has the same configuration as the customized Ubuntu server. 

### 3.1  **(Optional, but highly recommended)** Avoid increasing the size of VM when creating a new LiveCD.

The  creation of a  LiveCD from a VM   expands the size of the virtual machine substantially. The reason is that for the creation of the ISO image, large parts of the Master VM are copied in a temporary directory. For this, the virtual disk of the Master VM is dynamically increased. To avoid increasing the size of the original VM of the Ubuntu server from Step 2 (*Install software on Ubuntu server*), create a copy of  VM. We call the original VM the *Master VM* and the copied VM the *Build VM*. 
Proceed as follows: 
 - After making changes to the *Master VM*  (running InstallBaremetalPC.sh or installing/removing packages), create a clone of the VM. The clone becomes the *Build VM*. 
 - Repeat Step 1b, i.e., selecting `USB 3.0 Controller` for the *Build VM*.
 - Start the *Build VM* and log in as `labuser'.
 - Next run the scripts to create an ISO LiveCD image and burn the ISO file to a flash drive. 
 - Once the flash drive is created, delete the *Build VM*.     

>**Hint:** Create four BuildVMs, one for each PC (PC1, PC2, PC3, PC4) and create four USB flash drives that each hold a LiveCD for one of the PCs. Label the flash drives and use them to configure the PCs in the Internet lab. 

### 3.2 Touch up 
Check the desktop background. Change it to match one of PC1, PC2, P3, PC4.


### 3.3  Run script that creates ISO image 

  - Check whether the *Build VM* has Internet access. If not, find the network interface name by typing `ip link` and identify the virtual network interface. Then enable the network interface (say with name *enp0s3*) and start a DHCP client with 

     ```
     $ sudo ifconfig enp0s3 up
     $ sudo dhclient enp0s3
     ```
     
   - Check for needed updates of packages
     ```
     $ sudo apt-get update --fix-missing
     ```
  - Change the hostname. To configure a LiveCD for `PC1`, type

     ```
     sudo hostnamectl set-hostname PC1
     ```

  - Check that the script `makeLiveCD.sh` is in the home directory. If not, download the script with

     ```
     $ wget  https://raw.githubusercontent.com/Internet-lab/LinuxPC/main/makeLiveCD.sh
     ```

  - Just before running the script clear the history of bash commands (to prevent that they are copied to the LiveCD) with
   
     ```     
     $ history -c     
     $ >.bash_history
     $ >.wget-hsts 
     ```
   
  - The shelll script `makeLiveCD.sh` creates an .iso image (“liveCD.iso”) from the current virtual machine. From the home directory of `labuser`, run the script with the command 
  ```
  $ sudo bash makeLiveCD.sh
  ```

The script asks a few times for information. If you do not know otherwise, select the default option.  The default location of the ISO script is `/tmp/liveCD/liveCD.iso`. 

>**Note:** Since the default location of *liveCD.iso* is in a subdirectory of `/tmp`, the ISO image is lost after rebooting. 



## 4. Create a bootable flash drive with LiveCD 

### 4.1 Insert flash drive
Insert a flash drive (min. 16 GB) into a USB port of the computer where Virtualbox is running. The flash drive must be mounted in the *Build VM*. 
Sometimes the Ubuntu VM is unable to grab the flash drive, i.e., it does not appear as a drive. In this case, select the Ubuntu VM in the VM Manager and go to Settings→ Ports → USB, and add the flash drive. Then removing and re-inserting the flash drive should show it in the Ubuntu VM. 

### 4.2 Install LiveCD on flash drive

a. Check that the script `createBootableUSB.sh` is in the home directory. If not, download the script with

```
$ wget  https://raw.githubusercontent.com/Internet-lab/LinuxPC/main/createBootableUSB.s
```
b. Identify the device name of the flash drive with the command 

```
$ sudo lsblk -p
```

Typically, the device name is /dev/sdb with one partition /dev/sdb1 (It can be /dev/sdc or /dev/sdc1). 

c. From the home directory of `labuser`, run the script with the command 

```
$ sudo bash createBootableUSB.sh
```

The script prompts for hardware specific information. In particular, the script requests to enter the device name of the flash drive (`/dev/sdb`).
Once the script is completed, remove the flash drive.  The flash drive contains  the ISO image (`root.iso`) and grub configuration files.

## 5. Installing the LiveCD on the hard drive 
Thee following instructions install the LiveCD on the hard drive of the target machine. 

>**Note: Copying the LiveCD to the hard drive will delete all partitions on the hard disk. All data on the hard disk will be lost.**

a. Check if the BIOS of the target machine is set so that the system first tries to boot from a flash drive. 

b. Insert the flash drive from Step 4 into the target system. Rebooting the target system starts the LiveCD from the flash drive. Log in as `labuser`.

c. You need to copy the shell script `createBootableUSB.sh` to the home directory of `labuser`. One option is to copy the file on a flash drive (different flash drive than created in Step 4). An alternative is to connect the target machine to the Internet and download the file. 

- To get Internet access, connect one of the Ethernet interfaces to an  network with access to a DHCP server und run the command

```
$ sudo dhclient
```


d. Identify the device names of the hard disk on the target system.  

```
$ sudo lsblk -p
```

In many cases the hard disk is `/dev/sda`. Verify that this is the case. 

e. From the home directory of `labuser`, run the script with the command 

```
$ sudo bash createBootableUSB.sh
```

When the script requests to enter the device name of the target drive, enter `/dev/sda`. If entered for the path of the ISO file, enter `/isodevice/`.  
f. Once the script has completed, reboot the target machine and remove the flash drive. 

