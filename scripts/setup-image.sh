#!/bin/bash
# This script prepares the "installer-config.txt" file for a custom raspbian-ua-netinst image
# Run it on the host you build the image on
# The resulting file should be placed on the SD-card alongside the cmdline.txt file

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
packages=git
hostname=$PIHOSTNAME
rootpw=$PASSWORD
timeserver=0.se.pool.ntp.org
timezone=Europe/Stockholm
EOF

echo "File installer-config.txt ready, make sure it is located in the same folder as build.sh, so the script will copy it to your raspbian-ua-netinstall SD-card alongside the cmdline.txt file"
