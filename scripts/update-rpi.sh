#!/bin/bash
# Perform system updates
# Clean up APT's cache to prevent / from getting full
# Set the limit to 200M
# Check before and after upgrades

ROOTFS_LIM=200000

function check_df () {
if [ $(df / | tail -1 | awk '{print $4}') -le $1 ]; then 
	apt clean
fi
}

check_df ${ROOTFS_LIM}

apt update
apt upgrade -y

check_df ${ROOTFS_LIM}

if [ "$(whoami)" == "root" ]; then
	reboot
else
	echo "Must be root. Sorry."
fi
