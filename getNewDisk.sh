#!/usr/bin/env ksh
#: Title : getNewDisk.sh
#: Date : 2013-10-23
#: Author : "Jorge Medina" <jmedina@hp.com>
#: Version : 0.4
#: Description : AIX vio server vscsi provisioner
#: license : BSD
#: Options : getNewDisk.sh -s all -c -f lun_file -a
#: NOTES:
# getNewDisk.sh -s all -c -f lun_file -a
# -g cfgmgr yes or not when -g is not present
# -s all find disks HITACHI IBM y EMC
# -c clean Defined state disks
# -f pases file with ID or WWN of
# new disks the ID of the appliance works in case are a EMC
# or HiTACHi, for other o all case is better use a WNN List.
# -a change and set the HA attributes needed
# -l make lsmap and parsed them to create a nice output 
# needed to use with flags -m -n
# -m make mkvdev mappings with label take it as param and start from count pases with -n
# -n refer to index number start counter list index 
# the VTD from 1 to n ie: lpar_oradb_001 or if exist and you need start in other value
# give another number
# TODO list:
# save a log to undo changes in devices.
# -t for check in the second vio server the result of the first
# and -o to generate files on the first vio server
# 
SEBINPATH=/usr/lpp/EMC/Symmetrix/bin
BITS=$(getconf KERNEL_BITMODE)
alias inq=$SEBINPATH/inq.aix${BITS}_51
alias vio=/usr/ios/cli/ioscli
wwnfile=syminq.txt
vtdfile=lsmap.txt
outfile=news.txt
lunfile=''
lsmap=''
clean=''
cfg=''
outfilesorted=''
###
# procedure defined_clean clean all devices in Defined state
# use for clean all devices in Defined state
# this function reduce the risk to deal with scans over 
# garbage of defined devices and leaf only a Available devices.
# @param void
# @return void
#
defined_clean()
{
	grep Defined $vtdfile | while read c1 c2 c3 c4 c5 c6
	do
			vio rmvdev -vtd $c1
			rmdev -dl $c2
	done 


	for i in $(lsdev -Cc disk |grep Defined|awk '{print $1}')
	do
		rmdev -dl $i
	done
}
##
# get IBM disk find and return list with 3 cols:
# hdisk applianceID WNN
#
getIBMdisk()
{
	for i in $(lspv |awk '{print $1}')
	do
		lscfg -vl $i |grep "Manufacturer" |grep "IBM" > /dev/null
		if [[ $? -eq 0 ]] ; then
			echo "$i   IBMID   $(lscfg -vl $i|grep "Serial Number.."|sed -e 's/\.//g'|sed -e 's/Serial Number//g'|tr -d ' ')"
		fi
	done
}

###
# Procedure lsmap exec lsmap -all and parsed it to get one line per disk
# information and saved into $vtdfile for future utilization.
# @param void
# @return $vtdfile
# add wwid column if don't see maybe need -s to generate wwwid file.
lsmap()
{
	rm -rf $vtdfile
	vio lsmap -all |while read line ;do
		aux=$(echo $line|awk '{print $1}')
		echo $aux | grep vhost > /dev/null
		if [[ $? -eq 0 ]] ;then
			vhostname=$(echo $line|awk '{print $1}')
			vscsi=$(echo $line|awk '{print $2}')
		fi
		echo $aux | grep VTD > /dev/null
		if [[ $? -eq 0 ]] ;then
			vtd=$(echo $line|awk '{print $2}')
		fi
		echo $aux | grep Status > /dev/null
		if [[ $? -eq 0 ]] ;then
			status=$(echo $line|awk '{print $2}')
		fi
		echo $aux | grep LUN > /dev/null
		if [[ $? -eq 0 ]] ;then
			lun=$(echo $line|awk '{print $2}'|sed -e s/0x//g |cut -c 1-12)
		fi
		echo $aux | grep Backing > /dev/null
		if [[ $? -eq 0 ]] ;then
			device=$(echo $line|awk '{print $3}')
		fi
        wwid=$(grep "$device " $wwnfile |awk '{print $NF}')
		echo $aux | grep Physloc > /dev/null
		if [[ $? -eq 0 ]] ;then
            echo $device |grep hdisk > /dev/null
            if [[ $? -eq 0 ]] ;then
                physloc=$(echo $line|awk '{print $2}')
                echo "$vtd $device $lun $vhostname $vscsi $status $wwid" >> $vtdfile
            fi
		fi		
	done
}

###
# this set_attr function change and set new sets for any hdisk
# for vio support no_reserve policy and round_robin algorithm.
# @param {hdisk_list}
# @return null
#
set_attr()
{
	for i in $(awk '{print $1}' $1)
	do 
		vio chdev -dev $i -attr reserve_policy=no_reserve algorithm=round_robin;
	done
}

###
# grep_luns function generate a output list
# with new hdisk scanned and check if it's correct
# @param $lunfile 
# @param $outfile
# @return $outfile
#
grep_luns()
{
	rm -rf $2
	for i in $(cat $1)
	do
		grep "$i" $wwnfile >> $2
	done
	l1=$(cat $1 |egrep "^[a-zA-z0-9]" |wc -l|tr -d ' ')
	l2=$(cat $2 |egrep "^[a-zA-z0-9]" |wc -l|tr -d ' ')
	if [[ $l1 -ne  $l2 ]]; then
		rm -rf $2
		echo "Don't find target LUN's "
		exit 0
	fi
	result=$(size_check $2)
	echo $result |grep "^Error" > /dev/null
	if [[ $? -eq 1 ]] ;then
		echo $result
		exit 0
	fi
}

size_check()
{
	for hdisk in $(awk '{print $1}' $1)
	do
		hsize=$(bootinfo -s $hdisk|tr -d ' ')
		if [[ $hsize -eq 0 ]];then
			echo "Error size 0 in $hdisk"
		fi
	done
	echo "OK"
}

###
# mkvdevs procedure generate vtd maps
# 
# @param $label
# @return $outfile
#
mkvdevs()
{	
	label=$1
	n=$2
	vhost=$3
	while true
	do
		clear
		echo "before continue, you need set_attr in the other vio server"
		echo "if you already do this in other vio server, respond [y] "
		echo "if not sure how continue respond [n] and press enter "
		read input
		if [[ $input == 'n' || $input == 'y' ]]; then
			break
		fi
	done
	if [[ $input == 'y' ]]; then
		for i in $(awk '{print $1}' $outfile)
		do
			if [[ ${#n} -eq 1 ]]; then
				zero='00'
			elif [[ ${#n} -eq 2 ]];	then
				zero='0'
			elif [[ ${#n} -eq 3 ]]; then
				zero=''
			fi
			vio mkvdev -vdev $i -vadapter $vhost -dev "${label}_${zero}${n}"
			n=$(expr $n + 1)
		done
	else
		echo "don't do nothing..."
		exit 1
	fi
}

usage()
{
	echo "$0  -s all -c -f {lun_file}"
	exit 1
}

while getopts f:s:m:n:v:o:t:galc opt
do
  case $opt in
	f)
		lunfile="$OPTARG" ;;
	s)
		scan="$OPTARG" ;;
	c)
		clean='yes' ;;
	m)
		label="$OPTARG" ;;
	l)	
		lsmap='yes' ;;
	a)	
		devfile="yes" ;;
	n)
		start="$OPTARG" ;;
	v)
		vhost="$OPTARG" ;;
	g)
		cfg='yes' ;;
	*)
		usage ;; 
   esac
done

if [[ $# -eq 0 ]]; then
	usage
fi

if [[ $lsmap == 'yes' ]]; then
	echo "getting virtual target devices..."
	lsmap
fi

if [[ $clean == 'yes' ]]; then
	echo "cleaning Defined devices"
	if [[ $lsmap  == 'yes' ]]; then	
		defined_clean
	else
		lsmap
		defined_clean
	fi
fi

if [[ $scan != '' ]]; then
	if [[ $cfg == 'yes' ]]; then
		cfgmgr  > /dev/null 2>&1
	fi
	if [[ $scan == "all" ]]; then
		inq -sym_wwn -nodots 2>/dev/null |grep hdisk |sed -e 's/\/dev\/r//g' |awk '{print $1"    "$3"    " $4}'  > $wwnfile
		inq -hds_wwn -nodots 2>/dev/null |grep hdisk |sed -e 's/\/dev\/r//g' |awk '{print $1"    HDSID    "$3}' >> $wwnfile
		getIBMdisk >> $wwnfile
	elif [[ $scan == "sym" ]]; then
		inq -sym_wwn -nodots 2>/dev/null |grep hdisk |sed -e 's/\/dev\/r//g' |awk '{print $1"    "$3"    " $4}'  > $wwnfile
	elif [[ $scan == "hds" ]]; then
		inq -hds_wwn -nodots 2>/dev/null |grep hdisk |sed -e 's/\/dev\/r//g' |awk '{print $1"    HDSID    "$3}' > $wwnfile
	elif [[ $scan == "ibm" ]]; then
		getIBMdisk > $wwnfile
	fi
fi

if [[ $lunfile !=  '' ]]; then
	echo "Getting new luns..."
	grep_luns $lunfile $outfile
fi

if [[ $devfile == 'yes' ]]; then
	set_attr $outfile
fi

if [[ $label != '' ]] &&  [[ $start -gt 0  ]] && [[ $vhost != '' ]]; then
	
	mkvdevs $label $start $vhost
fi
