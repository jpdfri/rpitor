#!/bin/bash
# Perform a cleanup of APT's cache to prevent / from getting full
# Set the limit to 200M
# Check before and after upgrades

if [ $(df / | tail -1 | awk '{print $4}') -le 200000 ]; then 
	apt-get clean
fi

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
rpi-update

if [ $(df / | tail -1 | awk '{print $4}') -le 200000 ]; then 
	apt-get clean
fi

reboot
