#!/bin/bash


if [ -z "$1" ]; then
    echo "Error: Missing argument to script."
    echo "Provide the full valid absolute path for the new directory as argument to script e.g. $s/installs."
    exit;
fi
if [ "${1:0:1}" != "/" ]; then
    echo "Error: $1 is not an absolute path"
    echo "Provide the full valid absolute path for the new directory as argument to script e.g. $s/installs."
    exit;
fi
if [ -d "$1" ]; then
    echo "Error: $1 exists";
    echo "Provide the full valid absolute path for the new directory as argument to script e.g. $s/installs."
    exit;
fi
dateNow=`date +%y%m%d%H%M%S`;
mkdir -p "$1" &> /tmp/logs_$dateNow
if [ $? -ne 0 ] ; then
    echo "Error: $1 is not an valid directory path/name"
    echo "Provide the full valid absolute path for the new directory as argument to script e.g. $s/installs."
    exit;
fi
currentTempDir="$1"
cd "$currentTempDir"

createDiretoryAndInstall()
{
    mkdir -p "$1/matlab_only"
    cd "$1/matlab_only"
    mw -using Bllvm sbinstallmatlab -from Bllvm -to $(pwd) -products MATLAB;
    mkdir -p "$1/matlab_stateflow"
    cd "$1/matlab_stateflow"
    mw -using Bllvm sbinstallmatlab -from Bllvm -to $(pwd) -products MATLAB,Stateflow;
    mkdir -p "$1/all_products"
    cd "$1/all_products"
    mw -using Bllvm sbinstallmatlab -from Bllvm -to $(pwd) -named-lic dacore
}

createDiretoryAndInstall $1 







