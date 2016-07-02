#!/bin/bash

# Path variables
# We assume the Git repo was cloned
SCRIPTS_PATH="/root/rpitor/scripts"
if [ ! -d $SCRIPTS_PATH ]; then
	echo "Please clone DFRI's \"rpitor\" Git repo to /root"
	exit 0
fi

NETWORK="$($SCRIPTS_PATH/check-ipsubnet.sh $(ifconfig eth0 | awk '$0 ~ /Bcast/ { print $2, $NF }' | sed -e 's/addr://g' -e 's/Mask://g'))"
grep -v ^sshd: /etc/hosts.allow > /etc/hosts.allow-new
mv /etc/hosts.allow-new /etc/hosts.allow
echo "sshd: $NETWORK" >> /etc/hosts.allow

# Rationale behind package pinning
# ???
if [ ! -f /etc/apt/preferences ]
then
  cat << EOF > /etc/apt/preferences
Package: *
Pin: release n=jessie
Pin-Priority: 300

Package: *
Pin: release o=Raspbian
Pin-Priority: -10
EOF
fi

if [ "$(grep -c "http://archive.raspbian.org/raspbian jessie" /etc/apt/sources.list)" = 0 ]
then
  echo "deb http://archive.raspbian.org/raspbian jessie main contrib non-free rpi" >> /etc/apt/sources.list
fi

export DEBIAN_FRONTEND=noninteractive

if [ "$(ls -la /var/lib/dpkg/updates | wc -l)" -ge "1" ]
then
  dpkg --configure -a
fi

egrep -v "$SCRIPTS_PATH/|exit 0" /etc/rc.local > /etc/rc.local-new
egrep "initial-boot|update-scripts" /etc/rc.local >> /etc/rc.local-new
egrep -v "initial-boot|update-scripts|start-tor" /etc/rc.local | grep "$SCRIPTS_PATH" >> /etc/rc.local-new
egrep "hwrng" /etc/rc.local >> /etc/rc.local-new
echo "exit 0" >> /etc/rc.local-new
mv /etc/rc.local-new /etc/rc.local
chmod u+x /etc/rc.local
