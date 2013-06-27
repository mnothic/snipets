#!/usr/bin/env ksh
vio=$(hostname| tr '[A-Z]' '[a-z]')
outfile=${vio}_fccheck.csv
lspath > lspath.txt
echo "vio ; hdisk ; wwid ; mapped ; vtd ; vhost ; algorithm ; reserve_policy ; hcheck_interval ; queue_depth ;fc name ; path ; fc name ; path" > $outfile
check_by_lun()
{	
	lun=$1
	hdisk=$(grep $lun syminq.txt|awk '{print $1}'|tr -d ' ')
	vhost=$(grep "$hdisk " lsmap.txt|awk '{print $4}'|tr -d ' ')
	vtd=$(grep "$hdisk " lsmap.txt|awk '{print $1}'|tr -d ' ')
	algorithm=$(lsattr -El $hdisk |grep algorithm |awk '{print $2}'|tr -d ' ')
	policy=$(lsattr -El $hdisk |grep reserve_policy |awk '{print $2}'|tr -d ' ')
	qdepth=$(lsattr -El $hdisk |grep queue_depth |awk '{print $2}'|tr -d ' ')
	hcheck_interval=$(lsattr -El $hdisk |grep hcheck_interval |awk '{print $2}'|tr -d ' ')
	if [[ ${#hdisk} -gt 5 ]]; then
		map=$(grep "$hdisk " lsmap.txt|wc -l |tr -d ' ')	
		out="$vio ; $hdisk ; $lun ; $map ; $vtd ; $vhost ; $algorithm ; $policy ; $qdepth ; $hcheck_interval"
		for fc in $(grep "$hdisk " lspath.txt |grep Enable |awk '{print $3}' |awk '!($0 in a) {a[$0];print}' | tr '[A-Z]' '[a-z]')
		do
			fc_count=$(grep "$hdisk " lspath.txt |grep Enable |grep $fc |wc -l |tr -d ' ')
			out="$out ; $fc ; $fc_count"
		done
		echo $out >> $outfile
	fi
}

./gnd -s all -l -g

for i in $(awk '{print $3}' syminq.txt)
do
	check_by_lun $i
done
