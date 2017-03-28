#!/bin/bash
# initial-boot-setup-rpi2-raspbian-jessie.sh
# Script to prepare a fresh raspbian-ua-netinst setup on a Raspberry Pi 2

# Check if this has already been run
if [ -f /etc/dfri-setup-done ]
then
	exit 0
fi

# Path variables
# We assume DFRI's Git repo was cloned
SCRIPTS_PATH="/root/rpitor/scripts"
if [ ! -d $SCRIPTS_PATH ]; then
	echo "Please clone DFRI's \"rpitor\" Git repo to /root. Exiting."
	exit 1
fi

# Backup fstab
cp /etc/fstab /etc/fstab.orig
# New fstab to minimize SD-card wear
cat << EOF > /etc/fstab
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime,discard  0     1
tmpfs           /var/log        tmpfs   defaults,noatime,size=10% 0     0
tmpfs           /tmp            tmpfs   defaults,noatime,size=10% 0     0
EOF

# Force fsck at every boot
tune2fs -c 1 /dev/mmcblk0p2

# Update sources
apt-get update

# Configure the hardware RNG for entropy
# The module is now called bcm2835-rng and should be automatically loaded at boot time
# We force it otherwise
if [ ! -f /dev/hwrng ]; then
	modprobe bcm2835-rng
	echo "bcm2835-rng" >> /etc/modules-load.d/modules.conf
fi
# Install the necessary tools
if [ ! -f /usr/sbin/rngd ]; then
	apt-get update && apt-get install rng-tools
	sed -i 's/#HRNGDEVICE=\/dev\/hwrng/HRNGDEVICE=\/dev\/hwrng/' /etc/default/rng-tools
fi

sleep 10 # Fill entropy pool

# Regenerate ssh-keys - overwrite existing ones
cd /etc/ssh
rm -f *key*
for i in {rsa,dsa,ecdsa}; do
	echo -e  'y\n' | ssh-keygen -t $i -f ssh_host_"$i"_key -N ""
done

# Harden SSH moduli
awk '$5 < 2047 {$0 = "#" $0}{print}' moduli > moduli.fix
cp moduli.fix moduli

# Restart sshd
systemctl restart sshd

# Add Tor's Debian repo to sources
cat << EOF > /etc/apt/sources.list.d/tor.list
deb http://deb.torproject.org/torproject.org jessie main
deb-src http://deb.torproject.org/torproject.org jessie main
EOF

# Get Tor PGP keys and add them to APT's keyring
gpg --keyserver keys.gnupg.net --recv 886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# Install packages we want in place or make sure they are marked as manually installed
apt-get update

# Raspbian packages
apt-get install -y raspi-copies-and-fills raspberrypi-kernel raspberrypi-bootloader 

# Debian Jessie packages
apt-get install -y zlib1g-dev ntpdate perl openssl wget libevent-2.0-5

# UPnP - should we use something else? 
apt-get install -y miniupnpc

# make - required for the CPAN module
apt-get install -y make

# Tor 
apt-get install -y deb.torproject.org-keyring torsocks
apt-get install -y tor

# Don't forget perl-modules we use in scripts - TODO: use bash commands instead?
# Initialize CPAN
echo -e  '\n' | cpan

# Find the installed Perl version by querying dpkg and removing the minor revision number
PERL_VER=$(dpkg -l perl | tail -1 | awk '{ print $3 }' | cut -d- -f1)
if [ ! -f /usr/local/share/perl/"${PERL_VER}"/Net/IP.pm ]
then
	cpan -fi Net::IP 
fi

# Fix hosts.deny
echo "ALL: ALL" >> /etc/hosts.deny

# Fix hosts.allow - TODO: use "ip" instead of "ifconfig"
NETWORK="$($SCRIPTS_PATH/check-ipsubnet.sh $(ifconfig eth0 | awk '$0 ~ /Bcast/ { print $2, $NF }' | sed -e 's/addr://g' -e 's/Mask://g'))"
grep -v ^sshd: /etc/hosts.allow > /etc/hosts.allow-new
mv /etc/hosts.allow-new /etc/hosts.allow
echo "sshd: $NETWORK" >> /etc/hosts.allow

# Set timezone - if setup-image.sh was run, this should be redundant
if [ ! $(grep Stockholm /etc/timezone) ]; then
	echo "Europe/Stockholm" > /etc/timezone
	dpkg-reconfigure -f noninteractive tzdata
fi

# Set time - if setup-image.sh was run, this should be redundant, but we do it anyway since we've downloaded ntpdate
systemctl stop ntp
/usr/sbin/ntpdate 0.se.pool.ntp.org
systemctl start ntp

# setup empty crontab, just so that we can assume that a crontab already exists
if [ ! -f /var/spool/cron/crontabs/root ]
then
	echo "" > /tmp/root-crontab
	crontab /tmp/root-crontab
fi

# Setup cronjob, just in case, time keeping is important
RANDOM_MINUTE=$[ ( $RANDOM % 60 ) ]
crontab -l > /tmp/root-crontab
echo "# ntpdate, set time, important" >> /tmp/root-crontab
echo "${RANDOM_MINUTE} 1 * * * ( systemctl stop ntp ; /usr/sbin/ntpdate 0.se.pool.ntp.org ; systemctl start ntp ) > /dev/null 2>&1" >> /tmp/root-crontab
crontab /tmp/root-crontab

# Add another cronjob, update-rpi.sh
RANDOM_MINUTE=$[ ( $RANDOM % 60 ) ]
RANDOM_HOUR=$[ ( $RANDOM % 24 ) ]
RANDOM_MONTHDAY=$[ ( $RANDOM % 24 ) + 1 ]
crontab -l > /tmp/root-crontab
echo "# Update! RPI" >> /tmp/root-crontab
echo "${RANDOM_MINUTE} ${RANDOM_HOUR} ${RANDOM_MONTHDAY} * * $SCRIPTS_PATH/update-rpi.sh > /dev/null 2>&1" >> /tmp/root-crontab
crontab /tmp/root-crontab

# Add another cronjob, update-scripts.sh
RANDOM_MINUTE=$[ ( $RANDOM % 60 ) ]
RANDOM_HOUR=$[ ( $RANDOM % 24 ) ]
crontab -l > /tmp/root-crontab
echo "# Update! Scripts" >> /tmp/root-crontab
echo "${RANDOM_MINUTE} ${RANDOM_HOUR} * * * $SCRIPTS_PATH/update-scripts.sh > /dev/null 2>&1" >> /tmp/root-crontab
crontab /tmp/root-crontab

# Clean up some apt storage
apt-get autoremove -y
apt-get clean

# Fix rc.local to automatically start our scripts on boot
egrep -v "$SCRIPTS_PATH|exit 0" /etc/rc.local > /etc/rc.local-new
echo "$SCRIPTS_PATH/initial-boot-setup-rpi2-raspbian-jessie.sh" >> /etc/rc.local-new
echo "$SCRIPTS_PATH/on-rpi-boot.sh" >> /etc/rc.local-new
echo "$SCRIPTS_PATH/config-tor.sh" >> /etc/rc.local-new
echo "$SCRIPTS_PATH/backup-rpi.sh" >> /etc/rc.local-new
# Make hardware RNG device file world readable - to allow e.g. the "Tor" user to access it
echo "chmod a+r /dev/hwrng" >> /etc/rc.local-new
echo "exit 0" >> /etc/rc.local-new
mv /etc/rc.local-new /etc/rc.local
chmod u+x /etc/rc.local

# Make sure /etc/dfri-setup-done exists
touch /etc/dfri-setup-done

# Fix /boot/config.txt
cat << EOF > /boot/config.txt
gpu_mem=16
EOF

# And, as a final thing, just make sure the device is updated
$SCRIPTS_PATH/update-rpi.sh
