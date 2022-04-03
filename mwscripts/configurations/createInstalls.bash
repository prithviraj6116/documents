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
mkdir -p "$1" &> /tmp/logs
if [ $? -ne 0 ] ; then
    echo "Error: $1 is not an valid directory path/name"
    echo "Provide the full valid absolute path for the new directory as argument to script e.g. $s/installs."
    exit;
fi
currentTempDir="$1"
cd "$currentTempDir"

createDiretoryAndInstall()
{
    mkdir -p "$1/$2/matlab_only"
    cd "$1/$2/matlab_only"
    mw -using Bllvm sbinstallmatlab -P $3 -from Bllvm -to $(pwd) -products MATLAB;
    mkdir -p "$1/$2/matlab_stateflow"
    cd "$1/$2/matlab_stateflow"
    mw -using Bllvm sbinstallmatlab -P $3 -from Bllvm -to $(pwd) -products MATLAB,Stateflow;
    mkdir -p "$1/$2/all_products"
    cd "$1/$2/all_products"
    mw -using Bllvm sbinstallmatlab -P $3 -from Bllvm -to $(pwd)
}

createDiretoryAndInstall $1 "maci" "maci64"
createDiretoryAndInstall $1 "windows" "win64"
createDiretoryAndInstall $1 "debian" "glnxa64"







