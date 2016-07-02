#!/bin/bash
# This will remove the node-specific stuff from the Rpi2
rm -rf /etc/ssh/*key*
rm -rf /root
apt-get purge -y tor && apt-get autoremove --purge -y
apt-get clean
echo "exit 0" > /etc/rc.local
mkdir /root
