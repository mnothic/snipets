#!/usr/local/bin/bash
##
# base.bash
###
n_day=`date +%e | tr -d '[:space:]'`
h_start=`date '+%H:%M'`
to_day=`date '+%Y%m%d'`
yesterday=`date -v-1d '+%Y%m%d'`
date_string=`date +%d/%m/%Y`
log_dir=/var/log
hostname=`uname -n`
os=`uname -sr`
access=sudo
scriptpath='/ziz/scripts'

print_head ()
{
        clear
        strlen=$(echo $1 | wc -c)
        spaces=$(expr 54 - $strlen)
        spaces=$(expr ${spaces} / 2)
        print_margin $spaces
        echo "${1}"
        echo "                                                      "
        echo " ${date_string}                                ${hostname}"
        echo
}

print_margin ()
{
        x=1
        while [ true ]; do
                echo -n " "
                if [ $x -gt $1 ]; then
                        break
                fi
                let x=$x+1
        done
        unset x
}

get_selected ()
{
        unset func
        unset arg1
        unset arg2
    echo -e " Seleccione opción :\c "
    sw=0
    while [ $sw -eq 0 ]; do
        read op
        if [[ 'q' == $op || 'Q' == $op ]]; then
            exit 0
        fi
        x=1
            for opt in $(cat ${scriptpath}/${1}.opt) ; do
                if [ $x -eq $op ]; then
                        func=$(echo ${opt} | awk '{split($0, a, ";");print a[2]}')
                        func=$(echo $func | tr -d ' ')
                        export func
                        arg1=$(echo ${opt} | awk '{split($0, a, ";");print a[3]}')
                        arg1=$(echo $arg1 | tr -d ' ')
                        export arg1
                        arg2=$(echo ${opt} | awk '{split($0, a, ";");print a[4]}')
                        export arg2
                                sw=1
                        fi
            let x=$x+1 
        done
        if [ $sw -eq 0 ] ; then
            clear
            print_menu $1 $2
            continue 
        fi 
        if [ $sw -eq 1 ]; then
                $func $arg1 $arg2
        fi
    done
}

get_sub_selected ()
{
    unset func
    unset arg1
    unset arg2
    echo -e " Seleccione opción :\c "
    sw=0
    while [ $sw -eq 0 ]; do
        read op
        x=1
        if [[ 'q' == $op || 'Q' == $op ]]; then
                sw=1
            return 0
        fi
        for opt in $(cat ${scriptpath}/${1}.opt) ; do
            if [ $x -eq $op ]; then
                func=$(echo ${opt} | awk '{split($0, a, ";");print a[2]}')
                func=$(echo $func | tr -d ' ')
                export func
                arg1=$(echo ${opt} | awk '{split($0, a, ";");print a[3]}')
                export arg1
                arg2=$(echo ${opt} | awk '{split($0, a, ";");print a[4]}')
                export arg2
                sw=2
            fi
            let x=$x+1 
        done
        if [ $sw -eq 0 ] ; then
            clear
            print_sub_menu $1 $2
            continue
        fi 
        if [ $sw -eq 2 ]; then
            $func $arg1 $arg2
        fi
    done
}

print_menu ()
{
        IFS=$'\n'
        i=0
        print_head $2
        for str in $(cat ${scriptpath}/${1}.opt); do
                let i=$i+1
                echo -n  "        ${i}) "
                echo $str | awk '{split($0, a, ";");print a[1]}'
        done
#       let i=$i+1
#       echo "        ${i}) Salir"
    echo "        Q) Salir"
        echo;echo
        get_selected $1 $2
}

print_sub_menu ()
{
    IFS=$'\n'
    i=0
    print_head $2
    for str in $(cat ${scriptpath}/${1}.opt); do  
        let i=$i+1
        echo -n  "        ${i}) "
        echo $str | awk '{split($0, a, ";");print a[1]}'
    done
#    let i=$i+1
#    echo "        ${i}) Volver"
    echo "        Q) Volver"
    echo;echo
    get_sub_selected $1 $2
}
