#!/bin/bash
# Just make sure that we're running on-rpi-boot.sh on every boot

# Path variables
# We assume the Git repo was cloned
SCRIPTS_PATH="/root/rpitor/scripts"
# Determine the current Git remote and banch
GIT_REMOTE=$(cd ${SCRIPTS_PATH} && git remote -v | head -1 | awk '{ print $2 }')
GIT_BRANCH=$(cd ${SCRIPTS_PATH} && git branch | grep '*' | cut -d\  -f2)

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
git clone ${GIT_REMOTE} -b ${GIT_BRANCH}
if [ $? -eq 0 ]
then
  rm -rf rpitor-saved
else
  mv rpitor-saved rpitor
fi

