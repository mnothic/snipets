#!/usr/bin/env ksh
vio=$(hostname| tr '[A-Z]' '[a-z]')
outfile=${vio}_fccheck.csv
lspath > lspath.txt
echo "vio ; hdisk ; wwid ; mapped ; fc name ; path ; fc name ; path ; fc name ; path ; fc name ; path " > $outfile
fc_check_by_lun()
{  
	hdisk=$(grep $lun syminq.txt|awk '{print $1}'|tr -d ' ')
	lun=$1
	if [[ ${#hdisk} -gt 5 ]]; then
		map=$(grep "$hdisk " lsmap.txt|wc -l |tr -d ' ')	
		out="$vio ; $hdisk ; $lun ; $map"
		for fc in $(grep "$hdisk " lspath.txt |grep Enable |awk '{print $3}' |awk '!($0 in a) {a[$0];print}' | tr '[A-Z]' '[a-z]')
		do
			fc_count=$(grep "$hdisk " lspath.txt |grep Enable |grep $fc |wc -l |tr -d ' ')
			out="$out ; $fc ; $fc_count"
		done
		echo $out >> $outfile
	fi
}
# this is getNewDisk.sh script
./gnd -s all -l

for i in $(awk '{print $3}' syminq.txt)
do
	fc_check_by_lun $i
done
