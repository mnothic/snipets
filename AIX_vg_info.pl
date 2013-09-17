!/usr/bin/perl
use strict;
my (@vgs,$vg,@output,$line,$type,$maxpvs,$maxppsperpv);
my ($activepvs,$ppsize,$total,$factor,$maxdisk);
@vgs = `lsvg -o | sort`;

print "                                        Max           Max  \n";
print "                                        PP's    PP    disk \n";
print "                    Max   Used  VG      per     Size  size \n";
print "VG Name      Type   PV's  PV's  Factor  PV      (MB)  (MB) \n";
print "-----------------------------------------------------------\n";
foreach $vg (@vgs){
        chomp($vg);
        @output = `lsvg $vg`;
        $ppsize = $maxpvs = $activepvs = $type = $maxppsperpv = "";
        foreach $line (@output){
                if ($line =~ /PP SIZE:\s+(\d+)\s+mega.*/) {$ppsize = $1;}
                if ($line =~ /MAX PVs:\s+(\d+).*/) {$maxpvs = $1;}
                if ($line =~ /ACTIVE PVs:\s+(\d+).*/) {$activepvs = $1;}
                if ($line =~ /MAX PPs per PV:\s+(\d+).*/) {$maxppsperpv = $1;}
        }
        $total=$maxpvs*$maxppsperpv;
        $maxdisk=$ppsize*$maxppsperpv;
        if ($maxpvs == 1024) {
                $type = "scale";
        }elsif (($total >= 22352) && ($total <= 32512)){
                $type = "orig";
        }elsif (($total >= 87376) && ($total <= 130048)){
                $type = "big";
        }else{
                print "error determining VG type\n";
                next;
        }

        if ($type eq "orig" || $type eq "big"){
                $factor = $maxppsperpv/1016
        }else{
                $factor = "N/A";
                $maxppsperpv = "N/A";
                $maxdisk = $ppsize*2097152;
        }

        printf "%-12s %-6s %-5s %-5s ",$vg,$type,$maxpvs,$activepvs;
        printf "%-7s %-7s %-5s %-7s \n",$factor,$maxppsperpv,$ppsize,$maxdisk;
}
