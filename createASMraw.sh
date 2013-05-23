#!/usr/bin/env ksh
###
# @ScriptName: create_raw
# @Author: Jorge Medina
# @Date: 30-04-2013
# @Version: 0.1
# @license: BSD
# 
# create a file with all hdisk named target.txt
# and exec the script with a label name ie: asm_example
# 
label=$1
n=1
for i in $(awk '{print $1}' target.txt)
do
  mm=$(ls -l /dev/$i |awk '{print $5" "$6}')
	major=$(echo $mm|awk '{split($0,a,","); print a[1]}')
	minor=$(echo $mm|awk '{split($0,a,","); print a[2]}'|tr -d ' '|tr -d '[:alpha:]')
	l=$n
	if [ ${#n} -eq 1 ]; then
		l="00$n"
	elif [ ${#n} -eq 2 ]; then
		l="0$n"
	fi
	mknod /dev/$label_$l c $major $minor
	n=$(expr $n + 1)
done
