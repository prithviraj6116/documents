#!/bin/bash
logdir=/mathworks/devel/sandbox/$USER/misc/logs/qualification;
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




if [ -n "$lcm2update" ]; then
    export sbclone='1';
    export sbclonefromspecificjob='';
    export rp='';
    export sbcluster="Blcmdacore2"
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
echo smartbd=$smartbd;
echo lcm2update=$lcm2update;
echo testlist=$testlist;
echo macro=$macro;
echo unbp=$unbp;
echo unbp2=$unbp2;
echo cfg=$cfg;
echo runallunder=$runallunder;
echo sbmcoverage=$sbmcoverage;
echo testsuites=$testsuites;
echo selector=$selector;

mailToMe1()
{
    if [  -f $mypath/"$1".11bash ]; then
        cp $mypath/"$1".bash $mypath/"$1".txt
    fi
}

mailToMe()
{
    if [  -f $mypath/"$1".bash ]; then
        cp $mypath/"$1".bash $mypath/"$1".txt
        mail -s "$2 $1"  -A $mypath/"$1".txt  $USER@mathworks.com<<EOF
"$2 $1"
EOF
    fi
}

sbmcover()
{
    rm CoverageSFinML.txt;
    find toolbox/matlab/codetools/+matlab/+codetools/+internal/ -name "sfxfile.m" >> CoverageSFinML.txt;
    find toolbox/stateflow/stateflow/+Stateflow/+App/+Studio -name "*m" >> CoverageSFinML.txt;
    find toolbox/stateflow/stateflow/+Stateflow/+App/+Cdr -name "*m" >> CoverageSFinML.txt;
    find toolbox/shared/stateflow -name "*m" >> CoverageSFinML.txt;
    sbmcovsetup -disable
    sbmcovsetup -cover "CoverageSFinML.txt";
    #sbmcovsetup -opened
}

mailToMe21()
{
    if [  -f $mypath/"$1".11bash ]; then
        cp $mypath/"$1".bash $mypath/"$1".txt
    fi
}
mailToMe2()
{
    if [  -f $mypath/"$1".log ]; then
        cp $mypath/"$1".log $mypath/"$1".txt
        mail -s "$2 $1"  -A $mypath/"$1".txt  $USER@mathworks.com<<EOF
"$2 $1"
EOF
    fi
}
if [ -n "$originalQualifyBash" ]; then
    echo "#!/bin/bash" &>> $mypath/sbqualify.bash;
    echo '' &>> $mypath/sbqualify.bash;
    echo export dateNow=\`date +%y%m%d%H%M\` &>> $mypath/sbqualify.bash;
    echo export name=$name\_repro_\$dateNow \#qualification-reproduction for sandboxname $name &>> $mypath/sbqualify.bash;
    echo export sbcluster=$sbcluster &>> $mypath/sbqualify.bash;    
    echo export sbclone=1 &>> $mypath/sbqualify.bash;
    echo export sbclonefromspecificjob=$sbclonefromspecificjob &>> $mypath/sbqualify.bash;    
    echo export p4syncchangelists=\"$p4syncchangelists\" &>> $mypath/sbqualify.bash;
    echo export rp="\$(dirname \$(readlink -f \$0))/sbresolvedrestorepoint" \#copied from $rp on `date` &>> $mypath/sbqualify.bash after resolving conflicts;
    echo export lcm2update=\"$lcm2update\" &>> $mypath/sbqualify.bash;    
    echo export ctb=\"$ctb\" &>> $mypath/sbqualify.bash;
    echo export smartbd=$smartbd\" &>> $mypath/sbqualify.bash;    
    echo export testlist=\"$testlist\" &>> $mypath/sbqualify.bash;
    echo export macro=\"$macro\" &>> $mypath/sbqualify.bash;
    echo export unbp=\"$unbp\" &>> $mypath/sbqualify.bash;
    echo export unbp2=\"$unbp2\" &>> $mypath/sbqualify.bash;
    echo export cfg=\'$cfg\" &>> $mypath/sbqualify.bash;
    echo export runallunder=\"$runallunder\" &>> $mypath/sbqualify.bash;
    echo export sbmcoverage=\"$sbmcoverage\" &>> $mypath/sbqualify.bash;
    echo export testsuites=\"$testsuites\" &>> $mypath/sbqualify.bash;
    echo export selector=\'$selector\" &>> $mypath/sbqualify.bash;
    echo unset originalQualifyBash &>> $mypath/sbqualify.bash;
    mailToMe "sbqualify" "$name"
    
fi



if [ -n "$sbclone" ]; then
    cd $s;
    if [ -n "$sbclonefromspecificjob" ]; then
        mw -using $sbcluster sbs clone create -cluster $sbcluster.j"$sbclonefromspecificjob" -name $name &> $mypath/sbclonecreate.log $pdb;
    else
        mw -using $sbcluster sbs clone create -cluster $sbcluster -name $name &> $mypath/sbclonecreate.log $pdb;        
    fi
fi
mailToMe2 "sbclonecreate" "$name"

cd $s/$name/matlab;
if [ -n "$originalQualifyBash" ]; then
    jobNumber=`sbver | grep '^SyncFrom:' | grep -o -P '(?<=_job).*(?=_pass)'`;    
    export sbclonefromspecificjob=$jobNumber;    
    echo export sbclonefromspecificjob=$sbclonefromspecificjob &>> $mypath/sbqualify.bash;
    runningScript=`readlink -f $0`;
    echo bash $runningScript &>> $mypath/sbqualify.bash;
fi

if [ -n "$p4syncchangelists" ]; then
    IFS=' ' read -r -a array <<< "$p4syncchangelists";
    for element in "${array[@]}"
    do
        echo "syncing" $element &>> $mypath/sbp4syncchangelists.log;
        p4 sync @=$element &>> $mypath/sbp4syncchangelists.log;        
    done
fi
mailToMe2 "sbp4syncchangelists" "$name"

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
        readarray -t changelistsArr <<<"$changelists"
        i=0
        chg=${changelistsArr[i]};
        while [ -n "$chg" ]
        do
            tokens=( $chg );
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
            i=$((i+1));
            chg=${changelistsArr[i]};    
        done
        
        sbbackup -cn $changelistNumber -r $mypath -l sbresolvedrestorepoint &>>$mypath/sbbackupresovled.log;
    fi
elif [ -n "$lcm2update" ]; then
    yes | mw lcmupdate $lcm2update &> $mypath/sblcm2update.log;
fi


mailToMe2 "sbp4sync" "$name"
mailToMe2 "sbrestore" "$name"
mailToMe2 "sbp4autoresolve" "$name"
mailToMe2 "sbbackupresovled" "$name"
mailToMe2 "sblcm2update" "$name"


if [ -n "$ctb" ]; then
    mw ch validate --complete &> $mypath/sbchvalidate.log;
    sbmake -distcc DEBUG=1 CTB="$ctb" &> $mypath/sbmake.log;
fi
mailToMe2 "sbmake" "$name"
if [ -n "$smartbd" ]; then
    mw ch validate --complete &> $mypath/sbchvalidate.log;
    sbsmartbuild -opened &> $mypath/sbsmartbuild.log;
fi
mailToMe2 "sbsmartbuild" "$name"
if [ -n "$testlist" ]; then
    mw runlikebat -logs /tmp -testlist $testlist &> $mypath/sbrunlikebat.log;
elif [ -n "$unbp" ]; then
    mw runlikebat -logs /tmp -unbp $unbp  &> $mypath/sbrunlikebat.log;
elif [ -n "$macro" ]; then
    mw runlikebat -logs /tmp -macro $macro &> $mypath/sbrunlikebat.log;
fi
mailToMe2 "sbrunlikebat" "$name"    
runlogname='version';
if [ -n "$cfg" ]; then
    sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -cfg $cfg -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2 -session-priority 2 &> $mypath/sbruntests_cfg.log;
    runlogname='cfg';
fi
mailToMe2 "sbruntests_cfg" "$name"    
if [ -n "$selector" ]; then
    if [ -n "$unbp2" ]; then
        sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel   -unbp $unbp2 -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2   -session-priority 2 &> $mypath/sbruntests_selector.log;
    else
        sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -selector  $selector  -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2   -session-priority 2 &> $mypath/sbruntests_selector.log;
    fi
    runlogname='selector';    
fi
mailToMe2 "sbruntests_selector" "$name"    
if [ -n "$runallunder" ]; then
    if [ -n "$sbmcoverage" ]; then
        sbmcover
    fi
    sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -runallunder $runallunder -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2   -session-priority 2 -unbp g1951218 -unbp g1922971 -unbp g2016208 &> $mypath/sbruntests_runallunder.log;
    #sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -runallunder $runallunder -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2   -session-priority 2 &> $mypath/sbruntests_runallunder.log;
    runlogname='runallunder';    
fi
mailToMe2 "sbruntests_runallunder" "$name"    
if [ -n "$testsuites" ]; then
    sbruntests -opened -Fop sbcheck -rerunusing jobarchive -autofarm devel -testsuites  $testsuites  -rename-previous-test-log-area "$runlogname" -sbscanlog-interval 30m -mail 2   -session-priority 2 &> $mypath/sbruntests_testsuites.log;
fi
mailToMe2 "sbruntests_testsuites" "$name"    
