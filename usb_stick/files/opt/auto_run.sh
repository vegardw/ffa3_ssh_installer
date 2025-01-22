#!/bin/sh

WORK_DIR=/opt
MACHINE=Adventurer3
PID=0008

# Port used by socat for forwarding serial port over the network,
# for running klipper on a separate device
SOCAT_PORT=5038

for i in 1 2 3 4;
do
  if [ ! -e /dev/sda$i ]; then
     echo "sda$i not exist"
	 if [ ! -e /dev/sda ];then
     	continue
	 else
	 	echo "find /dev/sda. start mount."
  		mount -t vfat -o rw /dev/sda /mnt
	 fi
  else
  	mount -t vfat -o rw /dev/sda$i /mnt
  fi

  if [ $? -ne 0 ]; then
        echo "mount /dev/sda or /dev/sda$i to /mnt failed"
        continue
  else
  		ls -1t /mnt/Adventurer3*.tgz
		if [ $? -eq 0 ];then
			UPDATEFILE=`ls -1t /mnt/Adventurer3*.tgz | head -n 1`
			if [ -f $UPDATEFILE ];then
				echo "find update file: ${UPDATEFILE}"
				rm -rf /data/update
				cp -a ${UPDATEFILE} /data/
				if [ $? -ne 0 ];then
					rm -rf /data/Adventurer3*.tgz
					sync
					umount /mnt
					break
				fi
				sync
				mkdir -p /data/update
				:qsync
				SRCFILE="/data/`basename ${UPDATEFILE}`"
				if [ -f ${SRCFILE} ];then
					tar -xzvf ${SRCFILE} -C /data/update/
					sync
					rm -rf ${SRCFILE}
					/data/update/flashforge_init.sh ${MACHINE} ${PID}
					if [ $? -eq 0 ];then
						umount /mnt
						rm -rf /data/update
						sleep 100000
					fi
					umount /mnt
					rm -rf /data/update
					break
				fi
			fi
		fi

        if [ -f /mnt/flashforge_init.sh ]; then
             echo "found /mnt/flashforge_init.sh"
             chmod a+x /mnt/flashforge_init.sh
             /mnt/flashforge_init.sh ${MACHINE} ${PID}
			 if [ $? -eq 0 ];then
				umount /mnt
				sleep 100000
			 fi
             umount /mnt
             break
        fi
        umount /mnt
  fi
done

if [ -f /opt/DONT_START_SOFTWARE ]; then
	rm /opt/DONT_START_SOFTWARE
	/etc/init.d/network restart
	exit 0	
fi

echo 19 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio19/direction
echo 1 > /sys/class/gpio/gpio19/value
echo 19 > /sys/class/gpio/unexport

if [ -f /opt/KLIPPER ]; then
	/etc/init.d/network restart
	nohup socat TCP-LISTEN:$SOCAT_PORT,reuseaddr,fork GOPEN:/dev/ttyS1,raw,nonblock,echo=0,b230400 &
	exit 0
fi

if [ -d /data/update ];then
	rm -rf /data/update
fi

art_check=`hexdump -n 2 /lib/firmware/mt7628.eeprom | head -n 1 | awk '{print $2}'`

if [ "${art_check}" != "7628" ];then
    echo "/lib/firmware/mt7628.eeprom -- error"
    rm -rf /lib/firmware/mt7628.eeprom
    sync
    dd if=/dev/mtd2 of=/lib/firmware/mt7628.eeprom bs=1 count=512
    sync
fi

rm -rf /data/picture/*.jpg
/opt/PROGRAM/ffstartup-mipsle -f /opt/PROGRAM/ffstartup.cfg
