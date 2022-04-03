#!/bin/bash

export name='Qsfx33'
export sbclone=''
export sbcluster="Bsfml"

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

logdir=/mathworks/devel/sandbox/$USER/misc/logs/coverage;
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



echo '' &>> $mypath/sbqualify.bash;
echo export dateNow=\`date +%y%m%d%H%M\` &>> $mypath/sbcov.bash;
echo export sbclone=$sbclone &>> $mypath/sbqualify.bash;    
echo export sbclone=$sbclone &>> $mypath/sbqualify.bash;    

cd $s;
if [ -n "$sbclone" ]; then
    mw -using $sbcluster sbs clone create -cluster $sbcluster -name $name &> $mypath/sbclonecreate.log;        
fi

cd $s/$name;

find matlab/toolbox/stateflow/src/stateflow/sf_cdr matlab/toolbox/stateflow/src/stateflow/sf_xform matlab/toolbox/stateflow/src/stateflow/cdr matlab/toolbox/stateflow/src/stateflow/fsm -name '*.cpp' -or -name '*.c' | grep -v -e '/unittest/' -e '/pkgtest/' | tee 2cover.txt
sbbcovbuild -extrabuildargs "NORUNTESTS=1 NOBUILDTESTS=1 DISABLE_OBJ_GCC47=1 DISABLE_WARNINGS_AS_ERROR=1" -distcc -nounit -cover 2cover.txt  
sbruntests  -testsuites sfcore  -setup source_to_test
