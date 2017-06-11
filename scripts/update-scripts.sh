#!/bin/bash

# Path variables
# We assume the Git repo was cloned
SCRIPTS_PATH="/root/rpitor/scripts"
# Determine the current Git remote and banch
GIT_REMOTE=$(cd ${SCRIPTS_PATH} && /usr/bin/git remote -v | /usr/bin/head -1 | /usr/bin/awk '{ print $2 }')
GIT_BRANCH=$(cd ${SCRIPTS_PATH} && /usr/bin/git branch | /bin/grep '*' | /usr/bin/cut -d\  -f2)

if [ ! -d $SCRIPTS_PATH ]; then
	/bin/echo "Please clone DFRI's \"rpitor\" Git repo to /root"
	exit 0
fi

# Just make sure that we're running on-rpi-boot.sh on every boot
if [ "$(/bin/grep -c on-rpi-boot.sh /etc/rc.local)" != "1" ]
then
  /bin/echo "$SCRIPTS_PATH/on-rpi-boot.sh" >> /etc/rc.local
  #$SCRIPTS_PATH/on-rpi-boot.sh
fi

/bin/grep -v "exit 0" /etc/rc.local > /etc/rc.local-new
/bin/echo "exit 0" >> /etc/rc.local-new
/bin/mv /etc/rc.local-new /etc/rc.local
/bin/chmod u+x /etc/rc.local

cd /root
if [ -d $SCRIPTS_PATH ]
then
  /bin/mv rpitor rpitor-saved
fi

/usr/bin/git clone ${GIT_REMOTE} -b ${GIT_BRANCH}
# Exec flag
/bin/chmod u+x /root/rpitor/scripts/*.{sh,pl}

if [ $? -eq 0 ]
then
  /bin/rm -rf rpitor-saved
else
  /bin/mv rpitor-saved rpitor
fi

