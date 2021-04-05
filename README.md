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

## 1. Install software on Ubuntu server
a. Start the Ubuntu server in Virtualbox and log in as `labuser`. 
b. From the home directory of `labuser` download the script "InstallBaremetalPC.sh" using the command 

```$ wget  https://raw.githubusercontent.com/Internet-lab/LinuxPC/main/InstallBaremetalPC.sh```

c. Execute the script with the command 

```$ sudo bash InstallBaremetalPC.sh```

 - The script installs  software packages and sets configuration files needed in the Internet Lab (as well as some additional software). 
 - The script also downloads the shell scripts `makeLiveCD.sh` and `createBootableUSB.sh`.
