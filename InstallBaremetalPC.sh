#!/bin/bash
#
# Script to install software for the "baremetal" version 
# of the PCs for the Internet Lab 
#
# - assumes a bare bones Ubuntu server LTS 20.04 
# - intended use it to install on a Virtualbox VM, 
#   which is then used to create a LiveCD.  
# 
# April 2021

############################################################
# Setup error handling

set -e # exit whan a command fails

# echo an error message for debugging before exiting
trap '[ $? == 0 ] || >&2 echo "ERROR: \"${BASH_COMMAND}\" command filed with exit code $?."' EXIT

#---------------------(V03)---------------------
sudo apt -y -qq update
sudo apt -y -qq upgrade

# install gnome and lxterminal 
sudo apt -y -qq install wireshark gnome-session lxterminal gnome-screenshot mousepad
sudo apt -y -qq autoremove --purge byobu
#--------------------- (V04) ---------------------
# interface configuraiton added 
#------------------------------------------
cat <<EOF | sudo tee >/dev/null /etc/netplan/00-installer-config.yaml 
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      optional: true

    eth1:
      dhcp4: no
      optional: true
EOF
sudo apt -y -qq install members net-tools
#---------------------(V05) ---------------------
# Skip install of Virtualbox Guest Addition
# Instructions are as follows
# 1-    Start VirtualBox.
# 2-    Start the guest in question.
# 3-    Once the guest has booted, click Devices | Insert Guest Additions CD Image.
# 4-    Log in to your guest server.
# 5.1-  sudo mkdir /media/cdrom
# 5.2-  Mount the CD-ROM with the command 
#       sudo mount /dev/cdrom /media/cdrom.
# 6-    Change into the mounted directory with the command cd /media/cdrom.
# 7-    Install the necessary dependencies with the command 
#       sudo apt -y -qq install -y dkms build-essential linux-headers-generic linux-headers-$(uname -r)
# 8-    Change to the root user with the command sudo su.
# 9-    Install the Guest Additions package with the command ./VBoxLinuxAdditions.run.
# 10-   Allow the installation to complete.
# 
# After reboot
# 
# sudo usermod -aG vboxsf labuser
# or
# sudo adduser labuser vboxsf
# 
# =====================
# on VirtualBox
#------------------------------------------

#--------------------- (V06) ---------------------
# Don't have: yaml files updated eth0 IP address assigned by rc_local file.txt
#--------------------- (V07) ---------------------
# Skip Chrome install. Here are instructions: 
# wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# sudo apt -y -qq install ./google-chrome-stable_current_amd64.deb
# 
# sudo reboot
# 
# sudo rm google-chrome-stable_current_amd64.deb
#--------------------- (V08) ---------------------
# next lines are commented since they are repeated further below
#--------------------- (V08) ---------------------
#   Should non-superusers be able to capture packets?  YES
#sudo apt -y -qq install wireshark
#sudo usermod -aG wireshark labuser
#--------------------- (V10) ---------------------
sudo apt -y -qq install firefox
# 
#===================== TCP LAB SOFTWARE =========================
# ---------------------------------------
# Install net-tools on Ubuntu 20.04
# ---------------------------------------
# Jorg: seems to be already installed with 20.04 server
sudo apt -y -qq install net-tools

# ---------------------------------------
# install telnet server
# ---------------------------------------
sudo apt -y -qq install telnetd  

# ---------------------------------------
# Install traceroute/traceroute6
# ---------------------------------------
sudo apt -y -qq install inetutils-traceroute 

# ---------------------------------------
# Install iperf & iperf3
# ---------------------------------------
sudo apt -y -qq install iperf iperf3

# ---------------------------------------
# Install TFTP-HPA client & server
# Usage:
# sudo /etc/init.d/tftp-hpa {start|stop|restart|force-reload|status}
# ---------------------------------------
sudo apt -y -qq install tftpd-hpa tftp-hpa

# to start TFTP server
# sudo /etc/init.d/tftp-hpa {start|stop|restart|force-reload|status}
# or
# sudo service tftpd-hpa {start|stop|restart|force-reload|status}

# https://help.ubuntu.com/community/TFTP
# Create directore "tftpboot" in the home directory of user "labuser"

sudo mkdir /home/labuser/tftpboot
sudo chown -R tftp /home/labuser/tftpboot

sudo cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.original
cat <<EOF | sudo tee >/dev/null /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/home/labuser/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
EOF
# ---------------------------------------
# Install FTP Server
# Jorg: Doesn't this install a second telnet server? 
# ---------------------------------------
sudo apt -y -qq install vsftpd xinetd       

# ---------------------------------------
# Install arping
# http://linux-ip.net/html/tools-arping.html
# https://www.poftut.com/arping-command-tutorial-examples-linux/
# ---------------------------------------
sudo apt -y -qq install arping  

# ---------------------------------------
# Install Bridge Utilities
# brctl
# ---------------------------------------
sudo apt -y -qq install bridge-utils

# ---------------------------------------
# Install quagga
# ---------------------------------------
sudo apt-cache policy quagga
sudo apt -y -qq install quagga

cat <<EOF | sudo tee >/dev/null /etc/quagga/daemons
zebra=yes
bgpd=no 
ospfd=yes
ospf6d=no
ripd=yes   
ripngd=no
isisd=no
babeld=no
EOF

sudo cp /usr/share/doc/quagga-core/examples/zebra.conf.sample /etc/quagga/zebra.conf
sudo cp /usr/share/doc/quagga-core/examples/ripd.conf.sample /etc/quagga/ripd.conf
sudo cp /usr/share/doc/quagga-core/examples/bgpd.conf.sample /etc/quagga/bgpd.conf
sudo cp /usr/share/doc/quagga-core/examples/ospfd.conf.sample /etc/quagga/ospfd.conf
sudo cp /usr/share/doc/quagga-core/examples/pimd.conf.sample /etc/quagga/pimd.conf
sudo cp /usr/share/doc/quagga-core/examples/ripngd.conf.sample /etc/quagga/ripngd.conf
sudo cp /usr/share/doc/quagga-core/examples/ospf6d.conf.sample /etc/quagga/ospf6d.conf
sudo cp /usr/share/doc/quagga-core/examples/vtysh.conf.sample /etc/quagga/vtysh.conf
sudo cp /usr/share/doc/quagga-core/examples/isisd.conf.sample /etc/quagga/isisd.conf
sudo chown quagga.quaggavty /etc/quagga/*.conf
sudo chmod 640 /etc/quagga/*.conf  

# ---------------------------------------
# Install DHCP Server & Client
# 
# Stop prevent the server from starting at reboot by
# sudo update-rc.d isc-dhcp-server disable
# ---------------------------------------
sudo apt -y -qq install isc-dhcp-server   
# Client is already included, no need to install
#sudo apt -y -qq install isc-dhcp-client

# ---------------------------------------
# Install BIND9: DNS Server
# ---------------------------------------
sudo apt -y -qq install bind9 bind9utils 


# ---------------------------------------
# Install ethtool 
# ---------------------------------------
sudo apt -y -qq install ethtool # was already installed

# ---------------------------------------
# Install nmap
# This utility is not used in  Networking Lab
# but it is a  useful tool to have handy
# ---------------------------------------
sudo apt -y -qq install nmap 

# ---------------------------------------
# Install Wireshark [Not for GNS3]
# ---------------------------------------
sudo apt -y -qq install wireshark

# ---------------------------------------
# Post Wireshark Configurations
# ---------------------------------------
# During the installation, it will require to confirm security about 
# allowing non-superuser to execute Wireshark.
#
# Just confirm YES if you want to. If you check on NO, you must run 
# Wireshark with sudo. later, if you want to change this,
# The next command allows to reconfigure the setting 
sudo usermod -aG wireshark labuser
# Answer YES when prompted
# sudo dpkg-reconfigure wireshark-common  
# sudo usermod -aG vboxsf labuser    <--- does not exist in this install

# ---------------------------------------
# Install minicom 
# ---------------------------------------
sudo apt -y -qq install minicom 
# ---------------------------------------
# Install CKermit 
# ---------------------------------------
#sudo apt -y -qq install ckermit
# ---------------------------------------
# Install ssh 
# ---------------------------------------
sudo apt -y -qq install openssh-server

# ---------------------------------------
# Deactivate firewall
# ---------------------------------------
sudo service ufw stop

# ---------------------------------------
# Utilities 
# ---------------------------------------
sudo apt -y -qq install dnsutils unzip zip

# ---------------------------------------
# openvswitch
# ---------------------------------------
sudo apt -y -qq install -y openvswitch-switch

# ---------------------------------------
# scapy 
#   Not used in the Internet Lab, but 
#   could be used for experimenting with 
#   malformed packets. 
#   You may want to skip the installation 
# ---------------------------------------
sudo apt -y -qq install scapy

# ---------------------------------------
# File manager 
# ---------------------------------------
sudo apt -y -qq install nemo

# ---------------------------------------
# Disable password for labuser 
# ---------------------------------------
cat <<EOF | sudo tee --append >/dev/null /etc/sudoers
labuser ALL=(ALL) NOPASSWD:ALL
EOF

# ---------------------------------------
# Download wallpaper for PCs
# ---------------------------------------
sudo cp ./PC-wallpaper/PC{1,2,3,4}.png /usr/share/backgrounds/

cat <<EOF | sudo tee >/dev/null /usr/share/gnome-background-properties/ubuntu-wallpapers.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper>
    <name>PC1</name>
    <name xml:lang="ca">PC1</name>
    <filename>/usr/share/backgrounds/PC1.png</filename>
    <options>zoom</options>
    <pcolor>#2c001e</pcolor>
    <scolor>#2c001e</scolor>
    <shade_type>solid</shade_type>
  </wallpaper>
  <wallpaper>
    <name>PC2</name>
    <name xml:lang="ca">PC2</name>
    <filename>/usr/share/backgrounds/PC2.png</filename>
    <options>zoom</options>
    <pcolor>#2c001e</pcolor>
    <scolor>#2c001e</scolor>
    <shade_type>solid</shade_type>
  </wallpaper>
  <wallpaper>
    <name>PC3</name>
    <name xml:lang="ca">PC3</name>
    <filename>/usr/share/backgrounds/PC3.png</filename>
    <options>zoom</options>
    <pcolor>#2c001e</pcolor>
    <scolor>#2c001e</scolor>
    <shade_type>solid</shade_type>
  </wallpaper>
  <wallpaper>
    <name>PC4</name>
    <name xml:lang="ca">PC4</name>
    <filename>/usr/share/backgrounds/PC4.png</filename>
    <options>zoom</options>
    <pcolor>#2c001e</pcolor>
    <scolor>#2c001e</scolor>
    <shade_type>solid</shade_type>
  </wallpaper>
</wallpapers>
EOF

# ---------------------------------------
# Install bokeh server 
#   Bokeh is a visualization tool. It is not used in the 
#   Internet Lab, but used for another set of Labs on 
#   Linux scheduling.  
#   You may want to skip the installation 
# ---------------------------------------
sudo apt -y -qq install python3-pip
pip3 install bokeh
sudo apt -y autoremove
# ---------------------------------------
# Set Activities 
# ---------------------------------------
gsettings set org.gnome.shell favorite-apps "['lxterminal.desktop', 'wireshark.desktop', 'mousepad.desktop', 'nemo.desktop', 'org.gnome.Screenshot.desktop']"
# ---------------------------------------

# ---------------------------------------
# Reboot 
# ---------------------------------------
sudo reboot
