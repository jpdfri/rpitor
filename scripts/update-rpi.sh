#!/bin/bash
# Perform system updates
# Clean up APT's cache to prevent / from getting full
# Set the limit to 200M
# Check before and after upgrades

ROOTFS_LIM=200000

function check_df () {
if [ $(/bin/df / | /usr/bin/tail -1 | /usr/bin/awk '{print $4}') -le $1 ]; then 
	/usr/bin/apt clean
fi
}

check_df ${ROOTFS_LIM}

/usr/bin/apt update
/usr/bin/apt upgrade -y

check_df ${ROOTFS_LIM}

if [ "$(whoami)" == "root" ]; then
	/sbin/reboot
else
	echo "Must be root. Sorry."
fi
