#!/bin/bash
# This script prepares the "installer-config.txt" and "post-install.txt" files for a custom raspbian-ua-netinst image
# Run it on the host you build the image on
# The resulting files should be placed on the SD-card alongside the cmdline.txt file

# Some simple checks that are required
function check_binary_exists {
  which $1 > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "I need $1 to function. Please install. Bailing."
    exit 1
  fi
}
check_binary_exists whoami
check_binary_exists pwgen

# Some variables
PIHOSTNAME=$1
PASSWORD=$2
GIT_REPO=$3

# Checking if hostname is in arguments
if [ -z "${PIHOSTNAME}" ]
then
  PIHOSTNAME=DFRIfriendlypi$[ ( $RANDOM % 999 ) ]
  echo "Could not find a hostname, setting it to $PIHOSTNAME"
fi

# Random password
# We decided to use 8 characters, for readability reasons, also using "secure"-flag to make it slightly more random 
if [ -z "${PASSWORD}" ]
then
  PASSWORD=$(pwgen -B -s 8 1)
fi
echo "Setting ${PIHOSTNAME} and giving root-user the password: ${PASSWORD}"

cat << EOF > installer-config.txt
packages=git,rng-tools,zlib1g-dev,ntpdate,perl,openssl,wget,libevent-2.0-5,miniupnpc
hostname=$PIHOSTNAME
rootpw=$PASSWORD
timeserver=0.se.pool.ntp.org
timezone=Europe/Stockholm
EOF

# Check that the git repo is passed as an argument
if [ -z "${GIT_REPO}" ]
then
  GIT_REPO="https://github.com/DFRI/rpitor.git"
  echo "No Git repository provided, using $GIT_REPO"
fi

cat << EOF > post-install.txt
# post-install.txt
# Text file used by raspbian-ua-netinst to perform commands after the inital setup

# Clone the git repo
chroot /rootfs /usr/bin/git clone $GIT_REPO /rootfs/root/rpitor

# Fix rc.local to automatically start our scripts on boot
egrep -v "$SCRIPTS_PATH|exit 0" /rootfs/etc/rc.local > /rootfs/etc/rc.local-new
echo "$SCRIPTS_PATH/initial-boot-setup-rpi2-raspbian-jessie.sh" >> /rootfs/etc/rc.local-new
echo "$SCRIPTS_PATH/on-rpi-boot.sh" >> /rootfs/etc/rc.local-new
echo "$SCRIPTS_PATH/config-tor.sh" >> /rootfs/etc/rc.local-new
echo "$SCRIPTS_PATH/backup-rpi.sh" >> /rootfs/etc/rc.local-new
echo "exit 0" >> /rootfs/etc/rc.local-new
mv /rootfs/etc/rc.local-new /rootfs/etc/rc.local
chmod u+x /rootfs/etc/rc.local
EOF

echo "Files \"installer-config.txt\" and \"post-install.txt\" ready, make sure they are copied to the same folder as raspbian-ua-netinst\'s \"build.sh\" script, which will copy them to your raspbian-ua-netinstall SD-card."
