#!/bin/bash
logdir=/mathworks/devel/sandbox/$USER/qualificationLogs;
if [ -z "$originalQualifyBash" ]; then
    pdb='-pdb';
    export name=$name.pdb
else
    pdb='';
fi
    

mypath=$logdir/$name;
dateNow=`date +%y%m%d%H%M%S`;
if [ -d "$mypath" ]; then
    cd $mypath;
    versionDir=$mypath/version_$dateNow;
    echo "Warning: log directory $mypath exists. Copying its contents to $versionDir dir"
    mkdir -p $versionDir;
    mv sb* $versionDir;
else
    mkdir -p $mypath;
    echo "Creating log directory $mypath"
fi



if [ -d "$s/$name" ]; then
    if [ -n "$sbclone" ]; then
        echo "Error:sandbox already exists with this name"
        exit;
    fi
else 
    if [ -z "$sbclone" ]; then
        echo "Error:sandbox does not exist with this name";
        exit;
    fi
fi

if [ -n "$rp" ]; then
    if [ ! -d "$rp" ]; then
        echo "Error:restorepoint directory does not exist.";
        exit;
    elif [ -n "$originalQualifyBash" ]; then
        if [ -d "$mypath/sbrestorepoint" ]; then
            rm -rf $mypath/sbrestorepoint;
        fi
        cp -r $rp $mypath/sbrestorepoint;
    fi
fi


echo "qualifying with following configurations";
echo name=$name;
echo sbcluster=$sbcluster;
echo sbclone=$sbclone;
echo sbclonefromspecificjob=$sbclonefromspecificjob;
echo rp=$rp;
echo ctb=$ctb;
echo testlist=$testlist;
echo unbp=$unbp;
echo cfg=$cfg;
echo runallunder=$runallunder;
echo testsuites=$testsuites;

if [ -n "$originalQualifyBash" ]; then
    echo "#!/bin/bash" &>> $mypath/sbqualify.bash;
    echo '' &>> $mypath/sbqualify.bash;
    echo export dateNow=\`date +%y%m%d%H%M\` &>> $mypath/sbqualify.bash;
    echo export name=$name\_repro_\$dateNow \#qualification-reproduction for sandboxname $name &>> $mypath/sbqualify.bash;
    echo export sbcluster=$sbcluster &>> $mypath/sbqualify.bash;    
    echo export sbclone=1 &>> $mypath/sbqualify.bash;
    echo export sbclonefromspecificjob=$sbclonefromspecificjob &>> $mypath/sbqualify.bash;    
    echo export rp="\$(dirname \$(readlink -f \$0))/sbresolvedrestorepoint" \#copied from $rp on `date` &>> $mypath/sbqualify.bash after resolving conflicts;
    echo export ctb=$ctb &>> $mypath/sbqualify.bash;
    echo export testlist=$testlist &>> $mypath/sbqualify.bash;
    echo export unbp=$unbp &>> $mypath/sbqualify.bash;
    echo export cfg=$cfg &>> $mypath/sbqualify.bash;
    echo export runallunder=$runallunder &>> $mypath/sbqualify.bash;
    echo export testsuites=$testsuites &>> $mypath/sbqualify.bash;
    echo unset originalQualifyBash &>> $mypath/sbqualify.bash;
fi



if [ -n "$sbclone" ]; then
    cd $s;
    if [ -n "$sbclonefromspecificjob" ]; then
        mw -using $sbcluster sbs clone create -cluster $sbcluster.j"$sbclonefromspecificjob" -name $name &> $mypath/sbclonecreate.log $pdb;
    else
        mw -using $sbcluster sbs clone create -cluster $sbcluster -name $name &> $mypath/sbclonecreate.log $pdb;        
    fi
fi

cd $s/$name/matlab;
if [ -n "$originalQualifyBash" ]; then
    jobNumber=`sbver | grep '^SyncFrom:' | grep -o -P '(?<=_job).*(?=_pass)'`;    
    export sbclonefromspecificjob=$jobNumber;    
    echo export sbclonefromspecificjob=$sbclonefromspecificjob &>> $mypath/sbqualify.bash;
    runningScript=`readlink -f $0`;
    echo bash $runningScript &>> $mypath/sbqualify.bash;
fi

if [ -n "$sbp4sync" ]; then
    IFS=' ' read -r -a array <<< "$sbp4sync";
    for element in "${array[@]}"
    do
        cd $element;
        echo "syncing in" $PWD &>> $mypath/sbp4sync.log;
        p4 sync ... &>> $mypath/sbp4sync.log;        
        cd -;
    done
elif [ -n "$rp" ]; then
    if [ -z "$sbclone" ]; then
        p4 revert ...  &> $mypath/sbrestore.log;
        changelists=`p4 changelists -c $USER.$name`;        
        while [ -n "$changelists" ]
        do
            tokens=( $changelists );
            changelistNumber=${tokens[1]};
            p4 change -df  $changelistNumber &>> $mypath/sbrestore.log;
            changelists=`p4 changelists -c $USER.$name`;
        done
    fi
    sbrestore -f -no-prompt -restore-from $rp &>> $mypath/sbrestore.log;
    
    if [ -n "$originalQualifyBash" ]; then
        changelists=`p4 changelists -c $USER.$name`;
        tokens=( $changelists );
        changelistNumber=${tokens[1]};
        p4 resolve -am -c $changelistNumber &>> $mypath/sbp4autoresolve.log;
        manualresolverequired=`p4 resolve -n -c $changelistNumber`;
        while [ -n "$manualresolverequired" ]
        do
            echo "Following files needs manual resolve";
            echo $manualresolverequired;
            p4v ..;
            manualresolverequired=`p4 resolve -n -c $changelistNumber`;        
        done
        sbbackup -cn $changelistNumber -r $mypath -l sbresolvedrestorepoint &>>$mypath/sbbackupresovled.log;
    fi
fi


if [ -n "$ctb" ]; then
    sbmake -distcc DEBUG=1 CTB="$ctb" &> $mypath/sbmake.log;
fi

if [ -n "$testlist" ]; then
    mw runlikebat -logs /tmp -testlist $testlist &> $mypath/sbrunlikebat.log;
elif [ -n "$unbp" ]; then
    mw runlikebat -logs /tmp -unbp "$unbp" &> $mypath/sbrunlikebat.log;
fi
    
runlogname='version';
if [ -n "$cfg" ]; then
    sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -cfg         $cfg         -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2  &> $mypath/sbruntests.log;
    runlogname='cfg';
fi
if [ -n "$runallunder" ]; then
    sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -runallunder $runallunder -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2  &> $mypath/sbruntests.log;
    runlogname='runallunder';    
fi    
if [ -n "$testsuites" ]; then
    sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -testsuites  $testsuites  -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2  &> $mypath/sbruntests.log;
fi
