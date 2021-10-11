export ZFS_MASTER_SB="Bstateflow"
export SILENT=1
export LOCATION=AH
export BUILD_SRC_SIMULINK=1
export VISUAL=gvim
export EDITOR=gvim


function p4o {
    export PPP_P4OPENED=$(p4 opened)
    export PPP_SBROOT=$(sbroot)
    export PPP_SBVER=$(sbver)
    export PPP_COMMAND=p4o
    gvim $(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl) &
}

function g() {
    grep "$@" -iIrn --color=always --exclude=*tags
}

function vmd() {
    chd
    eval "gvim . &"
}
function getUserSbroot() {
    MYSBNAME=$(sbroot|cut -d'.' -f 2)
    MYSBROOT=$(sbroot)
    SBNAMEIFNETWORKSB=${PWD/$s\//}
    if [[ "$(sbroot)" != $d* ]]; then
        echo "$s/$MYSBNAME"
    else
        echo "$(sbroot)"
    fi
}
function chd() {
    export PPP_COMMAND=chd
    export PPP_DIRECTORYNUMBER='-1';
    export MYSBNAME=$(sbroot|cut -d'.' -f 2)
    export MYSBROOT=$(getUserSbroot)
    if [[ $# == 0 ]];
    then
        echo "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
        read -p "Enter directory number: " directoryNumber
        export PPP_DIRECTORYNUMBER=$directoryNumber
    else
        temp1=$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)
        export PPP_DIRECTORYNUMBER=$1
    fi
    cd "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
}
function getTerminalTabTitle() {
    PWD1=${PWD/$s/\$s}
    PWD2=${PWD1/$d/\$d}
    PWD3=${PWD2/$HOME/\~}
    #export MYSBROOT=$(sbroot|cut -d'.' -f 2)
    echo $PWD3
}

alias sbr="sb -r \"openExample('stateflow/AutomaticTransmissionUsingDurationOperatorExample');bdclose all;cd(matlabroot);startup; \" &> /tmp/matlab.log &";        
alias newSession="cd ~;rm -rf logs log matlab_crash_dump* orig.matlab_crash_dump*; pkill -9 -f matlab;sbstop 8 0;pkill -9 -f chrome;pkill -9 -f mozilla; pkill -9 -f firefox; pkill -9 -f p4v;pkill -9 -f gvim;cd -;google-chrome &> /tmp/chrome.log &"

export PS1=..............................................................................\\n$\ 
export PROMPT_COMMAND='echo -ne "\033]0;$(getTerminalTabTitle)\007"'

