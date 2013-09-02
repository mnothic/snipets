#!/usr/bin/env python
"""
Script for fs check in vmware vm with datastore in NAS

Jordi Molina - Sistemes SAP--
Jorge Medina - Sistemas UNIX++ 
Version 2.0 FTW

2011-05-20: afegit suport per snmp traps socks
2011-05-27: afegida funcio que detecta tots els fs ext2 i ext3 "JA NOT :)"
2011-06-22: afegida comprovacio de disponibilitat de paquet snmp-utils
2013-08-05: add install_snmp_utils()
2013-08-07: now support all ext fs.
2013-08-07: too many code fix and make it more pythonic
2013-08-07: catalan translation to english.
2013-08-08: add cron entry cron_activator()
2013-08-08: add is_virtual() 
2013-08-08: installable and runnable in everywhere
this script needs run as root
crontab line:
"""
import commands
import getopt
import sys
import os

SCRIPT_PATH = os.getcwd()

def is_virtual():
    cmd = "dmidecode |grep -i vmware"
    exit_code, out = commands.getstatusoutput(cmd)
    if exit_code == 0:
        return True
    return False
 

def add_job(file, job):
    try:
        fd = open(file,'a')
        fd.write(job + '\n')
        fd.close()
        return 0
    except IOError:
        return 1


def job_exist(file, pattern):
    # then file exist parse it to check if crontjob exist
    import re
    fd = open(file)
    while True:
        line = fd.readline()
        if not line:
            break
        if re.search(pattern,line) != None:
            return True
    return False
    
    
def cron_activator():
    crontab = "/var/spool/cron/root"
    cronjob = "*/5 * * * * /usr/bin/python " + SCRIPT_PATH + "/testfs.py -m"
    if not os.path.isfile(crontab):
        """ open crontab file of root user
            and write the line EOF
        """
        if add_job(crontab,cronjob) != 0:
            print "Can't write job into root crontab"
        else:
            print "Add cron job"
    else:
        if not job_exist(crontab, SCRIPT_PATH + "/testfs.py -m"):
            if add_job(crontab,cronjob) != 0:
                print "Can't write job into root crontab"
            else:
                print "Add cron job"
            

def fs_test(fs):
    """ fs_test returns 0 if is RW and 1 if is RO
	"""
    testfile = "test.tmp"
    try:
        fd = open(fs + testfile,"w")
        fd.write("test")
        fd.close()
        os.remove(fs + testfile)
        return 0
    except IOError:
        return 1

def usage():
    print ""
    print "Script test RW filesystem"
    print "============================"
    print ""
    print "Options"
    print "-------"
    print "-t : exec test mode"
    print "-m : exec real mode"
    print "-h : show help information"

def snmp_send(fs):
        cmd_trap = '/usr/bin/snmptrap -v 1 -c public ptgnssal.intranet.gasnatural.com 1.3.6.1.4.1.11.2.17.1 "" 6 99999998 "" 1.3.6.1.4.1.11.2.17.1.99999998.1 s '
        cmd_trap += fs
        exit_code, out = commands.getstatusoutput(cmd_trap)
        return exit_code

def get_fs():
    mtab = open("/etc/mtab","r")
    fs_list = []
    for raw_line in mtab:
        split_line = raw_line.split()
        if 'ext' == split_line[2][:3]:
            if split_line[1] == "/":
                fs_list.append(split_line[1])
            else:
                fs_list.append(split_line[1] + "/")
    mtab.close()
    return fs_list
    
	
def install_net_snmp_utils():
    """ install net-snmp if not exist in linux vm
    	added by Jorge Medina.
    """
    import yum
    package='net-snmp-utils'
    yb = yum.YumBase()
    if len(yb.rpmdb.searchNevra(name=package)) == 0:
        try:
            yb.install(name=package)
            yb.resolveDeps()
            yb.processTransaction()
        except yum.Errors.InstallError, err:
            print "Failed during install of "+ package +" package!"
            print sys.stderr +" "+ str(err)
            exit(1)


def main(argv):
    if is_virtual():
        cron_activator()
    else:
        exit(0)
    try:
        options, args = getopt.getopt(argv, "tmh", ["test","maquina", "help"])
    except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        usage()
        exit(2)
    if len(options) == 0:
        usage()
        exit()
    # check exist snmptrap binary
    if not os.path.isfile("/usr/bin/snmptrap"):
        print "WARNING: not installed the net-snmp-utils package"
        print "Proceeding to install net-snmp-util..."
        install_net_snmp_utils()

    #
    fs_list = get_fs()
    for opt, arg in options:
        if opt in ["-t", "--test"]:
            for fs in fs_list:
                if fs_test(fs) == 0:
                    print "Read Write fs " + fs
                else:
                    print "Read Only fs  " + fs
                    snmp_send("test_mon_fs_readonly")

        elif opt in ["-m", "--maquina"]:
            for fs in fs_list:
                if fs_test(fs) == 1:
                    #send snmp traps
                    snmp_send(fs)

        elif opt in ("-h", "--help"):
            usage()
            exit()

if __name__ == "__main__":
        main(sys.argv[1:])
