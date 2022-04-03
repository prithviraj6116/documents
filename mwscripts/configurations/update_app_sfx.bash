#!/bin/bash

logdir=/mathworks/devel/sandbox/$USER/misc/logs/qualification;
dateNow=`date +%y%m%d%H%M%S`;
name=sfxapp_$dateNow
name1=sfxapp
mypath=$logdir/$name;
client=$USER.$name
client1=$USER.$name1
sbdir=$s/$name
sbbackupdir=/mathworks/devel/sandbox/ppatil/_sbbackup/sbs_$client\_backup;
sbbackuplatest=$sbbackupdir/latest/
sbbackupdir1=/mathworks/devel/sandbox/ppatil/_sbbackup/sbs_$client1\_backup;
sbbackuplatest1=$sbbackupdir1/latest
cluster=Bsfml
versionDir=$mypath/version_$dateNow;


if [ -d "$mypath" ]; then
    echo "log directory exists. something is wrong"
    exit;
else
    echo "Creating log directory $mypath"
    mkdir -p $mypath;
fi

if [ -d "$sbdir" ]; then
    echo "sandbox exists, something is wrong"
    exit
else
    echo "sandbox does not exist, creating new one"
fi

cd $s
mw -using $cluster sbs clone create -c $cluster -n $name  &> $mypath/sbclone.log;

if [ -d "$sbdir" ]; then
    echo "sandbox is created"
else
    echo "sandbox is not created. something went wrong"
    exit
fi

cd $sbdir
echo "sbrestore started"
sbrestore -f -no-prompt -restore-from $sbbackuplatest1 &> $mypath/sbrestore.log;


echo "sbresolve started"
changelists=`p4 changelists -c $client`;
readarray -t changelistsArr <<<"$changelists"
i=0
chg=${changelistsArr[i]};
while [ -n "$chg" ]
do
    tokens=( $chg );
    changelistNumber=${tokens[1]};
    p4 resolve -am -c $changelistNumber  &> $mypath/sbresolve_$i.log;
    manualresolverequired=`p4 resolve -n -c $changelistNumber`;
    while [ -n "$manualresolverequired" ]
    do
        echo "Following files needs manual resolve";
        echo $manualresolverequired;
        p4v ..;
        manualresolverequired=`p4 resolve -n -c $changelistNumber`;        
    done
    i=$((i+1));
    chg=${changelistsArr[i]};    
done

echo "sbbackup after sbresolve started"
mv $sbbackuplatest1 $sbbackuplatest1\_$dateNow
cd $sbdir
sbbackup -opened &> $mypath/sbbackup.log;
cp -r $sbbackuplatest $sbbackuplatest1


echo "sbmake started"
cd $sbdir/matlab
sbmake -distcc DEBUG=1 CTB="stateflow_core stateflow stateflow_matlab_runtime appdesigner/appdesigner appdesigner/application_js appdesigner/application_m uicomponents/components_m uicomponents/appdesigner_plugin_m uicomponents/appdesigner_plugin_js uicomponents/core_js" &> $mypath/sbmake.log;


