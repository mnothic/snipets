#!/usr/bin/env bash
#: Title : RTPA GNI Checker
#: Date : 2013-07-24
#: Author : "Jorge Medina" <jmedina@hp.com>
#: Version : 1.0
#: Description : Check RTPA from chekcklist.csv
#: Options : ./rtpa.sh [ -h -f checklist.csv ]
#: NOTES:
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
	if [ -f $2 ]; then
		grep -v "^#" $2 | grep -i "$1" > /dev/null 2>&1 
		if [[ $? -eq 0 ]]; then
			echo 'PASS'
		else
			echo 'FAIL'
		fi
	else
		echo 'FAIL'
	fi
}

if [ ! -f $CHECKLIST ]; then
	echo $CHECKLIST" not exist"
	exit 0
fi

cat $CHECKLIST |while read line
do
	type=$(echo $line | awk '{split($0, a, ";");print a[1]}')
	desc=$(echo $line | awk '{split($0, a, ";");print a[2]}')
	pattern=$(echo $line | awk '{split($0, a, ";");print a[3]}')
	file=$(echo $line | awk '{split($0, a, ";");print a[4]}')

	case $type in
		'config')
			pattern="${pattern%"${pattern##*[![:space:]]}"}"
			status=$(search "$pattern" "$file")
			;;
		'process')
			status=$(running "$pattern")
			;;
		'file')
			status=$(exist "$pattern")
			;;
	esac
	if [[ $type == 'config' || $type == 'process' || $type == 'file' ]];then 
		len=${#desc}
		dif=$(expr 80 - $len)
		x=0
		spaces=""
		while [ $x -lt $dif ]
		do
			x=$(expr $x + 1)
			spaces="$spaces "
		done
		if [ $(uname -s) == 'Linux' ]; then
			if [ $status == 'FAIL' ]; then
				echo -n $desc
				echo -n "$spaces"
				echo -e "[\e[00;31m$status\e[00m]"
			else
				echo -n $desc
				echo -n "$spaces"
				echo -e "[\e[1;32m$status\e[00m]"
			fi
		else
			echo "$desc ${spaces}[$status]"
		fi
	fi
done
