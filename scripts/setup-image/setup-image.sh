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

read -p "Which branch do you wish to use? [master/devel] " GIT_BRANCH

cat << EOF > post-install.txt
# post-install.txt
# Text file used by raspbian-ua-netinst to perform commands after the inital setup

# Clone the git repo
chroot /rootfs /usr/bin/git clone -b ${GIT_BRANCH} ${GIT_REPO} /root/rpitor

# Checkout devel branch if instructed - commented out/archived; not working as intended
#if [ -n "${USE_DEVEL_BRANCH}" ] && [[ "${USE_DEVEL_BRANCH}" =~ [yY] ]]
#then
#  cat << EOF >> post-install.txt
# Checkout devel branch
#cd /rootfs/root/rpitor
#chroot /rootfs /usr/bin/git checkout devel
#EOF
#fi

# Make all scripts executable
chroot /rootfs /bin/chmod 755 /root/rpitor/scripts/*.sh
chroot /rootfs /bin/chmod 755 /root/rpitor/scripts/*.pl

# Fix rc.local to automatically start our scripts on boot
chroot /rootfs /bin/egrep -v "/root/rpitor/scripts|exit 0" /etc/rc.local > /rootfs/etc/rc.local-new
chroot /rootfs /bin/echo "/root/rpitor/scripts/initial-boot-setup-rpi2-raspbian-jessie.sh" >> /rootfs/etc/rc.local-new
chroot /rootfs /bin/echo "/root/rpitor/scripts/on-rpi-boot.sh" >> /rootfs/etc/rc.local-new
chroot /rootfs /bin/echo "/root/rpitor/scripts/config-tor.sh" >> /rootfs/etc/rc.local-new
chroot /rootfs /bin/echo "/root/rpitor/scripts/backup-rpi.sh" >> /rootfs/etc/rc.local-new
chroot /rootfs /bin/echo "exit 0" >> /rootfs/etc/rc.local-new
chroot /rootfs /bin/mv /etc/rc.local-new /etc/rc.local
chroot /rootfs /bin/chmod 744 /etc/rc.local
EOF

echo "Files \"installer-config.txt\" and \"post-install.txt\" ready, make sure they are copied to the same folder as raspbian-ua-netinst's \"build.sh\" script, which will copy them to your raspbian-ua-netinstall SD-card."
