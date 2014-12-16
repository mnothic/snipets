#!/bin/bash
#
# oracle Init file for starting and stopping
# Oracle Database. Script is valid for 10g and 11g versions.
#
# chkconfig: 35 80 30
# description: Oracle Database startup script
# shutdown.sql
#------CUT HERE-------
#shutdown immediate;
#exit
#------END CUT-------
# startup.sql
#------CUT HERE------
#startup;
#exit;
#------END CUT------
# Source function librar
. /etc/rc.d/init.d/functions

export ORACLE_BASE=/orabin/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=DWH
export ORACLE_OWNER="oracle"
export OWB_HOME=$ORACLE_HOME/owb
export PATH=$PATH:$ORACLE_HOME/bin:$OWB_HOME/bin/unix

case $1 in
    start)
          echo -n $"Starting Enterprise Manager"
          su - $ORACLE_OWNER -c "emctl start dbconsole"

          echo -n $"Starting Enterprise Manager agent"
          su - $ORACLE_OWNER -c "emctl start agent"
          su - $ORACLE_OWNER -c "emctl status agent"

          #start Oracle Listener
          echo -n $"Starting LISTENER"
          #nohup sh lsnrctl start > lsnrctl_start.log &
          su - $ORACLE_OWNER -c "$ORACLE_HOME/bin/lsnrctl start > lsnrctl_start.log"

          # Start Oracle Instance
          su - $ORACLE_OWNER -c "sqlplus / as SYSDBA @/home/oracle/startup.sql"
          echo -n $"Starting Oracle Instance"
          #nohup sh dbstart $ORACLE_HOME > sbstart.log &

          #Starting OWB
          export OWB_HOME=$ORACLE_HOME/owb
          export PATH=$PATH:$ORACLE_HOME/owb/bin/unix
          cd $OWB_HOME/bin/unix
          echo -n $"Starting Oracle Warehouse Builder Control Center"
          nohup sh startOwbbInst.sh  > startOwbbInst.log &
          ;;
    stop)
          cd $OWB_HOME/bin/unix
          echo -n $"Stopping OWB Control Center (provide the password oc4jadmin)"
          sh stopOWBBInst.sh > startOwbbInst.log
          cd $ORACLE_HOME/bin
          echo -n $"Shutdown Oracle Instance"
          su - $ORACLE_OWNER -c "sqlplus / as SYSDBA @/home/oracle/shutdown.sql"
          echo -n $"Stop Listener"
          su - $ORACLE_OWNER -c "lsnrctl stop"
          echo -n $"Stop EM"
          su - $ORACLE_OWNER -c "emctl stop dbconsole"
          ;;

    *)
          echo .Usage: $0 {start|stop}.
          ;;
esac
