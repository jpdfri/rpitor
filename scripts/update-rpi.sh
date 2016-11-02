#!/bin/bash
# Perform system updates
# Clean up APT's cache to prevent / from getting full
# Set the limit to 200M
# Check before and after upgrades

ROOTFS_SIZE_LIMIT=200000

if [ $(df / | tail -1 | awk '{print $4}') -le $ROOTFS_SIZE_LIMIT ]; then 
	apt-get clean
fi

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

if [ $(df / | tail -1 | awk '{print $4}') -le $ROOTFS_SIZE_LIMIT ]; then 
	apt-get clean
fi

reboot
