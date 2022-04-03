#!/bin/bash

cloneSSDSB()
{



    dirName=$s/misc/logs/backupCloneRestore/ssd/$2/$1/logs_$dateNow;
    mkdir -p $dirName;
    cd /local-ssd/$USER;    
    sbclone -backup-opened $2.latest_pass/ $1/ &> $dirName/sbclone.log;
    cd $1;
    #sbrestore -no-prompt -f  &> $dirName/sbrestore.log;
    #cd matlab;
    #sbmake DEBUG=1 CTB="stateflow_resources stateflow stateflow_core" &> $dirName/sbmake.log;
}

cloneNetworkSB()
{
    dirName=$s/misc/logs/backupCloneRestore/sbs/$2/$1/logs_$dateNow;    
    mkdir -p $dirName;
    ln -sf /mathworks/devel/sbs/$3/$USER.$1 $s/$1;    
    cd /mathworks/devel/sbs/$3/$USER.$1/matlab;
    sbmake DEBUG=1 CTB="stateflow_resources stateflow stateflow_core" &> $dirName/sbmake.log;        
}

dateNow=`date +%y%m%d%H%M%S`;
. /hub/share/sbtools/bash_setup.bash;
dirName=$s/misc/logs/backupCloneRestore/syncSSD/logs_$dateNow;


export PYTHONPATH=/sandbox/savadhan:/sandbox/savadhan/sbtools
  
mkdir -p $dirName/Bstateflow;
sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Bstateflow -src-root Bstateflow -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;
#mkdir -p $dirName/Beml;
#sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Beml -src-root Beml -prime-from /local-ssd/$USER/Bstateflow.latest_pass   -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;
#mkdir -p $dirName/Bmain_task1;
#sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Bmain_task1 -src-root Bmain_task1 -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;

#mkdir -p $dirName/Bsfml;
#sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Bsfml -src-root Bsfml -prime-from /local-ssd/$USER/Bstateflow.latest_pass   -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;
#sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Bsfml -src-root Bsfml -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;

#mkdir -p $dirName/Bmlcoder;
#sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Bmlcoder -src-root Bmlcoder -prime-from /local-ssd/$USER/Bstateflow.latest_pass   -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;
#sbsyncmaster -C /local-ssd/$USER -log-dir $dirName/Bmain -src-root Bmain -cfg /sandbox/$USER/misc/configurations/sbsync.cfg;



#cloneSSDSB "sf41" "Bstateflow";
#cloneSSDSB "sf42" "Bstateflow";
#cloneSSDSB "sf43" "Bstateflow";
#cloneSSDSB "l41" "Bsleditor";
#cloneSSDSB "l42" "Bsleditor";
#cloneSSDSB "l43" "Bsleditor";
#cloneSSDSB "sf2" "Bstateflow"
unset PYTHONPATH

#cloneNetworkSB "sf1_sbs" "Bstateflow" "29";
#cloneNetworkSB "l1_sbs" "Bsleditor" "50";




