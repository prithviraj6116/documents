export ZFS_MASTER_SB="Bstateflow"
export SILENT=1
export LOCATION=AH
export BUILD_SRC_SIMULINK=1
export VISUAL=gvim
export EDITOR=gvim

alias sbr="sb -r \"openExample('stateflow/AutomaticTransmissionUsingDurationOperatorExample');bdclose all;startup; \" &> /tmp/matlab.log &";        
alias newSession="cd ~;rm -rf logs log matlab_crash_dump* orig.matlab_crash_dump*; pkill -9 -f matlab;sbstop 8 0;pkill -9 -f chrome;pkill -9 -f p4v;pkill -9 -f gvim;cd -;google-chrome &> /tmp/chrome.log &"


function g() {
    grep "$@" -iIrn --color=always --exclude=*tags
}

function vmd() {
    chdir
    eval "gvim . &"
}

function chd() {
    if [[ $# == 0 ]];
    then
        export PPP_DIRECTORYNUMBER='-1';
        echo "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
        read -p "Enter directory number: " directoryNumber
        export PPP_DIRECTORYNUMBER=$directoryNumber
    else
        export PPP_DIRECTORYNUMBER=$1
    fi
    cd "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
}



