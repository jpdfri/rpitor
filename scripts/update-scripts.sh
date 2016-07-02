#!/bin/bash
# Just make sure that we're running on-rpi-boot.sh on every boot

# Path variables
# We assume the Git repo was cloned
SCRIPTS_PATH="/root/rpitor/scripts"
if [ ! -d $SCRIPTS_PATH ]; then
	echo "Please clone DFRI's \"rpitor\" Git repo to /root"
	exit 0
fi

if [ "$(grep -c on-rpi-boot.sh /etc/rc.local)" != "1" ]
then
  echo "$SCRIPTS_PATH/on-rpi-boot.sh" >> /etc/rc.local
  $SCRIPTS_PATH/on-rpi-boot.sh
fi

grep -v "exit 0" /etc/rc.local > /etc/rc.local-new
echo "exit 0" >> /etc/rc.local-new
mv /etc/rc.local-new /etc/rc.local
chmod u+x /etc/rc.local

cd /root
if [ -d $SCRIPTS_PATH ]
then
  mv rpitor rpitor-saved
fi
git clone https://github.com/DFRI/rpitor.git
if [ $? -eq 0 ]
then
  rm -rf rpitor-saved
else
  mv rpitor-saved rpitor
fi

