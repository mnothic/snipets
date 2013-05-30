#!/usr/bin/env bash
# quitar los discos desde la cabina
# y luego ejecuta el script
# https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Online_Storage_Reconfiguration_Guide/removing_devices.html

for i in $(multipath |grep "tur checker reports path is down" |awk '{print $1}' |tr -d ":")
do 
	multipath -f /dev/$i > /dev/null 2>&1;
	blockdev -flushbufs /dev/$i > /dev/null 2>&1; 
	echo 1 > /sys/block/${i}/device/delete > /dev/null 2>&1; 
	rm -rf /dev/${i} > /dev/null 2>&1;
done
