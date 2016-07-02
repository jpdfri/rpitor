#!/bin/bash
# Description
# This script will do what we need to configure the tor-node

# Path variables
SCRIPTS_PATH="/root/rpitor/scripts"
if [ ! -d $SCRIPTS_PATH ]; then
	echo "Please clone DFRI's \"rpitor\" Git repo to /root"
	exit 0
fi

# Small temporary addition to make sure that we're running "update-scripts.sh" every time we boot the rpi
if [ "$(grep -c update-scripts.sh /etc/rc.local)" != "1" ]
then
  echo "$SCRIPTS_PATH/update-scripts.sh" >> /etc/rc.local
  $SCRIPTS_PATH/update-scripts.sh
  sleep 10
fi

# Fetch 1MB-file to do a crude bandwitdh-test
SPEED=$(wget https://www.dfri.se/files/1Mb.file -O /dev/null 2>&1 | awk '$0 ~ /saved/ { print $3 }' | sed 's/(//g')
SPEED=$(perl -E "say ${SPEED}*1024/2.8" | sed 's/\..*$//g')
if [ "$SPEED" == "" ]
then
  SPEED=1024
fi

# Default port
MYPORT=9001

# Check IP
MYIP=$(ifconfig | awk '$0 ~ /inet/ && $0 !~ /127\.0\.0\.1/ { print $2 }' | sed 's/addr://g' | head -1)

# Verify if its a private IP
if [ "$($SCRIPTS_PATH/check-iptype.pl ${MYIP})" = "PRIVATE" ]
then 
  # It's a private IP, let's try to do some upnp-magic so we don't have to do portforwarding
  upnpc -a $MYIP $MYPORT $MYPORT TCP 2>&1 > /dev/null
fi

# If a local config-file exist, source it and let its variables override our own settings
#if [ -f /home/pi/.dfripi/tor-config ]
#then
#  source /home/pi/.dfripi/tor-config
#fi

# Backup the original config file, it has some nice documentation for the various options
cp /etc/tor/torrc /etc/tor/torrc.orig

# Setup config
cat << EOF > /etc/tor/torrc 
## DFRI's standard configuration for Tor relays
# Only run as a relay
SOCKSPort 0
ExitPolicy reject *:*

# Daemonize the process
RunAsDaemon 1

# Nickname only accepts alphanumerical symbols
Nickname $HOSTNAME

# User created by the Debian package
User debian-tor

# Which port do we use?
ORPort $MYPORT

# Throttle bandwidth 
RelayBandwidthRate $SPEED KBytes
RelayBandwidthBurst $SPEED KBytes

ContactInfo DFRI <rpitor AT dfri dot se>

DataDirectory /var/lib/tor

# Tor logs
# We use the syslog facility instead of /var/log/tor 
# (which would need to be recreated at every boot anyway
# since we mount /var/log as tmpfs)
Log notice syslog

# Log info:
# "Based on detected system memory, MaxMemInQueues is set to 693 MB. 
# You can override this by setting MaxMemInQueues by hand."
# Let's keep it frugal?
MaxMemInQueues 512 MB
EOF
exit 0
