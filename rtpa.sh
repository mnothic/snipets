#!/usr/bin/env [ba|k]sh
#: Title : Release to Production Acceptance at Hewlett Packard
#: Date : 2014-03-17
#: Author : "Jorge Medina" <jmedina@hp.com>
#: Version : 1.0
#: Description : Check RTPA  from chekcklist.csv
#: Options : ./rtpa.sh [ -h -f checklist.csv ]
#: NOTES:
#: install in $BASEDIR and download https://github.com/mnothic/nshell
#: RTPA CHECKER
#: works in AIX and LINUX
#:
BASEDIR='./'
. $BASEDIR/nshell.sh

##
# this show the options of the script
##
#:
#: here we parsing options flags
#: loop all shell args.

CHECKLIST="${BASEDIR}/$(lower $(get_os_name))_checklist.csv"

while getopts f:h opt
do
	case $opt in
		f)
			CHECKLIST="$OPTARG" ;;
		h)
			usage ;;
	esac
done

if [ $(file_exist $CHECKLIST) == 'NOT' ]; then
	echo $CHECKLIST" not exist"
    usage "[-f file.csv]"
fi
#:
#: here is where magic occurs
#: we deal with all options in csv
#:
cat $CHECKLIST |while read line
do
	#
	# here parsing the csv and tokenize it
	#
	type=$(echo $line | awk '{split($0, a, ";");print a[1]}')
	desc=$(echo $line | awk '{split($0, a, ";");print a[2]}')
	pattern=$(echo $line | awk '{split($0, a, ";");print a[3]}')
	file=$(echo $line | awk '{split($0, a, ";");print a[4]}')
	case $type in
		'config')
			status=$(find_string_in_file "$pattern" "$file")
			;;
		'process')
			status=$(running "$pattern")
			;;
		'file')
			status=$(file_exist "$pattern")
			;;
	esac
	#
	# here identify the type of the check
	# if is not identified pass to next or omitted it.
	#
	if [[ $type == 'config' || $type == 'process' || $type == 'file' ]]; then         
		if [[ $status == 'NOT' ]]; then
			echo "$(space_fill 80 right $desc)[$(color_string red FAIL)]"
		else
			echo "$(space_fill 80 right $desc)[$(color_string green PASS)]"
		fi
	fi
done
