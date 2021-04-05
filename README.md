# LinuxPC

The available scripts install a Live CD version of the Linux PC for the Internet Lab on a "baremetal" PC system.  
The process described here assumes that the installation is done in Virtualbox on a Mac or Windows or Linux system (The scripts also run on a native Linux installation).

Version:  April 2021
## 1. Install Ubuntu server 
a. Download Ubuntu Server 20.04 LTS from 
https://ubuntu.com/download/server

b. Install the Ubuntu server as a VM in Virtualbox (the development was done with Virtualbox 6.1). Allocate 2048 MB memory and 10 GB for the virtual disk.
During the installation, use the default settings. 

 * Agree to the installation of Openssh

 * For the user name password, select **Name: `Labuser`, userid: `labuser`, password: `labuser`**.

## 2. Install software on Ubuntu server
a. Start the Ubuntu server in Virtualbox and log in as `labuser`. 
b. From the home directory of `labuser` download the script "InstallBaremetalPC.sh" using the command 

```$ wget  https://raw.githubusercontent.com/Internet-lab/LinuxPC/main/InstallBaremetalPC.sh```

c. Execute the script with the command 

```$ sudo bash InstallBaremetalPC.sh```

 - The script installs  software packages and sets configuration files needed in the Internet Lab (as well as some additional software). 
 - The script also downloads the shell scripts `makeLiveCD.sh` and `createBootableUSB.sh`.
 - The script reboots the OS, when the system reboots it will show a login screen of the Gnome Desktop. Login as `labuser` and verify that the software installation is completed. 

## 3. Create an ISO LiveCD image
The next step creates a LiveCD ISO image, which has the same configurationas the customized Ubuntu server. 

a. **(Optional)** Avoid increasing the size of VM when creating a new LiveCD.

The  creation of a  LiveCD from a VM   expands the size of the virtual machine substantially. The reason is that for the creation of the ISO image, large parts of the Master VM are copied in a temporary directory. For this, the virtual disk of the Master VM is dynamically increased. To avoid increasing the size of the original VM of the Ubuntu server from Step 2 (*Install software on Ubuntu server*), create a copy of  VM. We call the original VM the *Master VM* and the copied VM the *Build VM*. 
Proceed as follows: 
 - After making changes to the VM  (running InstallBaremetalPC.sh or installing/removing packages), export the VM using “Export Appliance” in Virtualbox. The exported appliance is saved as an OVF file. 
 - Import the exported appliance to create a new VM. We call this version the *Build VM*. 
 - Start the *Build VM* and log in as `labuser'.
 - Next run the scripts to create an ISO LiveCD image and burn the ISO file to a flashdrive. Once the flashdrive is created, delete the *Build VM*.   


