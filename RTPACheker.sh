#!/usr/bin/env bash
# install in /home/gni/bin
# RTPA CHECKER
# works in AIX and LINUX
############################
BASEDIR='/home/gni/bin'
CHECKLIST=$BASEDIR'/checklist.csv'
usage()
{
  echo "$0 [-f file.csv]"
	exit 0
}
while getopts f:h opt
do
	case $opt in
		f)
			CHECKLIST="$OPTARG" ;;
		h)
			usage ;;
	esac
done

exist()
{
	if [[ -f '$1' ]]; then
		echo 'PASS'
	else
		echo 'FAIL'
	fi
}

running()
{
	ret=$(ps auxw |grep -i $pattern |grep -v grep|wc -l |tr -d ' ')
	if [[ $ret -gt 0 ]]; then
		echo 'PASS'
	else
		echo 'FAIL'
	fi
}

search()
{
	grep -i $1 $2 > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo 'PASS'
	else
		echo 'FAIL'
	fi
}

cat $CHECKLIST |while read line
do
	type=$(echo $line | awk '{split($0, a, ";");print a[1]}')
	desc=$(echo $line | awk '{split($0, a, ";");print a[2]}')
	pattern=$(echo $line | awk '{split($0, a, ";");print a[3]}')
	file=$(echo $line | awk '{split($0, a, ";");print a[4]}')
	case $type in
		'string')
			status=$(search $pattern $file)
			;;
		'process')
			status=$(running $pattern)
			;;
		'binary')
			status=$(exist $pattern)
			;;
	esac
	if [[ $type == 'string' || $type == 'process' || $type == 'binary' ]];then 
		echo "$desc [$status]"
	fi
done
