export ZFS_MASTER_SB="Bstateflow"
export SILENT=1
export LOCATION=AH
export BUILD_SRC_SIMULINK=1
export VISUAL=gvim
export EDITOR=gvim
export SBTOOLS_VNC_WINDOW_MGR=mate-session

function cd {
  command cd "$1"
  pwd > /tmp/terminal_pwd
}

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
    export MYSBNAME=$(echo $ORIGSBROOT|cut -d'.' -f 2-)
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
function p4o() {
    cd $(sbroot);
    gvim `p4 opened | cut -d "/" -f 5- | cut -d "#" -f 1 |  sed "s/.*/ &/"` &> /tmp/gvim1.log & 
    cd -
}
function gs1 {
a="gvim +/\"$1\" $(grep -irl $1 $2 $3 $4 $5 --exclude=*swp --exclude=*swo --exclude=*tags .)";
b=$(echo $a|tr '\n' ' ');
eval $b
} 

function cl {
 cmd1="$@ | xclip -selection clipboard"
# eval $1
cmd2="xclip -selection clipboard -o"
 eval $cmd1
 eval $cmd2
}

export h=/mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts


alias sbmakeq="sbmake -distcc DEBUG=1"
alias sbmakeq1="sbmake BH_ALLOW_ISOLATED_BUILDS= -distcc DEBUG=1"
alias sbmakeq2="sbmake NORUNTESTS=1 NOBUILDTESTS=1 BH_ALLOW_ISOLATED_BUILDS= -distcc DEBUG=1"
alias sbr="sb -r \"addpath('/mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts');myStartup;cd('~/Downloads/u1') \" &> /tmp/matlab.log &";        
alias mynote="cd /mathworks/devel/sandbox/ppatil/misc/hubdocs/notes/;gvim notes.txt & cd - "
alias newSession="cd ~;rm -rf logs log matlab_crash_dump* orig.matlab_crash_dump*; pkill -9 -f matlab;sbstop 8 0;pkill -9 -f chrome;pkill -9 -f mozilla; pkill -9 -f firefox; pkill -9 -f p4v;pkill -9 -f gvim;cd -;google-chrome &> /tmp/chrome.log & mynote &> /tmp/log1 &"
#export PS1=..............................................................................\\n$\ 
export PROMPT_COMMAND='echo -ne "\033]0;$(getTerminalTabTitle)\007"'


#temporary shortcuts
#alias gns="gvim index.js public/css/covreport.css public/index.html  public/js/covreport.js &"
alias gcf="cd /mathworks/devel/sandbox/ppatil/misc/gitRepo1/stateflow-tools/cov; gvim sbjobtracker_coverage.py  instrumentCoverage.py mwcov.hpp mwcov.cpp mwcovmex.cpp getPathTests.py runSfCovCronJob.py ../scripts/runOnLeasedMachine.py &"
alias gq="gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify1.bash &"
alias gns="cd /mathworks/devel/sandbox/ppatil/misc/gitRepo1/mwcppcoverage/; gvim  public/js/covreport.js routes/index.js app.js public/covreport.html public/css/covreport.css &"
export PATH=$PATH:/usr/local/go/bin


