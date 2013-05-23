#!/usr/bin/env ksh
# obtener cabeceras asm oracle 10g
# identificar y respaldar discos ASM
# el script busca discos marcados por ASM
# una vez identificados, respalda las cabeceras
# si configura la variable csv crea un listado csv.
# kfed merge disco text=path
csv=""
headerdir="/tmp"
if [[ ${#csv} -ne 0 ]]; then
  echo "AIX dev ; ASM dev; major ; minor" > $csv
fi

for i in $(ls -l /dev/hdisk*|awk '{print $10}') 
do 
	od -c $i|head -5 |grep "O   R   C   L   D   I   S   K" > /dev/null
	if [[ $? -eq 0 ]]; then 
		mm=$(ls -l $i |awk '{print $5" "$6}')
		major=$(echo $mm|awk '{split($0,a,","); print a[1]}')
		minor=$(echo $mm|awk '{split($0,a,","); print a[2]}'|tr -d ' '|tr -d '[:alpha:]')
		if [[ ${#minor} -eq 1 ]]; then
			mm="$major,  $minor"
		elif [[ ${#minor} -eq 2 ]];	then
			mm="$major, $minor"
		elif [[ ${#minor} -eq 3 ]];	then
			mm="$major,$minor"
		fi
		
		asmdev=$(ls -ld /dev/* |grep "$mm " |grep -v hdisk |awk '{print $NF}')
		hdisk=$(echo $i |awk '{split($0,a,"/");print a[3]}');
		su - oracle -c "kfed read $asmdev text=${headerdir}/$hdisk.head"
		if [[ ${#csv} -ne 0 ]];	then
			echo "$i ; $asmdev ; $major ; $minor " >> $csv
		fi
	fi
done

if [[ $1 == 'restore' ]]; then
	for i in $(ls -l ${headerdir}/hdisk*.head|awk '{print $NF}') 
	do
		diskname=$(echo $l|awk '{split($0,a,"."); print $1}')
		mm=$(ls -l /dev/$i |awk '{print $5" "$6}')
		asmdev=$(ls -ld /dev/* |grep "$mm " |grep -v hdisk |awk '{print $NF}')
		su - oracle -c "kfed merge $asmdev text=$i"
	done
fi
