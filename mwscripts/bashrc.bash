export ZFS_MASTER_SB="Bstateflow"
export SILENT=1
export LOCATION=AH
export BUILD_SRC_SIMULINK=1
export VISUAL=gvim
export EDITOR=gvim
export SBTOOLS_VNC_WINDOW_MGR=mate-session

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
    SBNAMEIFNETWORKSB=${PWD/$s\//}
    if [[ "$(sbroot 2>/tmp/log1)" != $d* ]]; then
        echo "$s/$1"
    else
        echo "$2"
    fi
}
function chd() {
    export PPP_COMMAND=chd
    export PPP_DIRECTORYNUMBER='-1';
    export ORIGSBROOT=$(sbroot 2>/tmp/log1)
    export MYSBNAME=$(echo $ORIGSBROOT|cut -d'.' -f 2)
    export MYSBROOT=$(getUserSbroot $MYSBNAME $ORIGSBROOT)
    export MYSBNAME=${MYSBNAME/$d\//(local)}
    if [[ $# == 0 ]];
    then
        echo "$(perl /mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts/bashrcHelper.pl)"
        read -p "Enter directory number: " directoryNumber
        export PPP_DIRECTORYNUMBER=$directoryNumber
    else
        temp1=$(perl /mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts/bashrcHelper.pl)
        export PPP_DIRECTORYNUMBER=$1
    fi
    cd "$(perl /mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts/bashrcHelper.pl)"
}
function getTerminalTabTitle() {
    PWD1=${PWD/$s/\$s}
    PWD2=${PWD1/$d/\$d}
    PWD3=${PWD2/$HOME/\~}
    #export MYSBROOT=$(sbroot|cut -d'.' -f 2)
    echo $PWD3
}
 
export h=/mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts
alias sbr="sb -r \"openExample('stateflow/AutomaticTransmissionUsingDurationOperatorExample');bdclose all;cd(matlabroot);addpath('/mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts');myStartup;cd('~/Downloads') \" &> /tmp/matlab.log &";        
alias mynote="cd /mathworks/devel/sandbox/ppatil/misc/hubdocs/notes/;gvim notes.txt & cd - &>/tmp/log1 &"
alias newSession="cd ~;rm -rf logs log matlab_crash_dump* orig.matlab_crash_dump*; pkill -9 -f matlab;sbstop 8 0;pkill -9 -f chrome;pkill -9 -f mozilla; pkill -9 -f firefox; pkill -9 -f p4v;pkill -9 -f gvim;cd -;google-chrome &> /tmp/chrome.log & mynote &> /tmp/log1 &"

export PS1=..............................................................................\\n$\ 
export PROMPT_COMMAND='echo -ne "\033]0;$(getTerminalTabTitle)\007"'

