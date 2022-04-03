# -*-shell-script-*-

# For information and guidelines on what should and should NOT go
# in here, please read sbsetupunix help:
#   http://inside.mathworks.com/wiki/SBTools#sbsetupunix
# In particular pay attention to the 'Typical Mistakes' that can cause
# significant pain to the company.
# You should also time your changes as explained in sbsetupunix help.


# Enable DEFAULT_SANDBOX to set a default sandbox for tools like sbm when not
# run from within a sandbox.
#export DEFAULT_SANDBOX=/mathworks/devel/sandbox/$LOGNAME/b
unset PYTHONPATH
. /mathworks/hub/share/sbtools/bash_setup.bash
unset LD_LIBRARY_PATH
source /mathworks/hub/share/sbtools/bash_setup.bash

export PATH=$PATH:/sandbox/savadhan/sbtools

source /sandbox/savadhan/sbtools/_bash_functions
export SBTOOLS_VNC_WINDOW_MGR=mate-session
export P4CONFIG=.perforce
export P4MERGE=p4merge












################
# My own macros
################
export ZFS_MASTER_SB="Bstateflow"
export SILENT=1
export LOCATION=AH
export BUILD_SRC_SIMULINK=1
alias qedit='gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify.bash';
alias sfmlt='go root;cd test/toolbox/stateflow/sf_in_matlab';
alias sfml='go root; cd toolbox/stateflow/stateflow/+Stateflow/+App';
alias sfmls='go root; cd toolbox/shared/stateflow/';
alias sfmld='go root; cd toolbox/stateflow/sfxdemos/internal';
alias sbr="sb -r 'vdp;bdclose all;' &> /tmp/matlab.log &";        
alias newSession="pkill -9 -f matlab;sbstop 8 0;pkill -9 -f chromi;pkill -9 -f p4v;pkill -9 -f gvim;chromium &> /tmp/chrome.log & "
function g() {
    grep "$@" -iIrn --color=always 
}
export PATH=$PATH:/sandbox/dandrade/tools/
export PATH=$PATH:/home/ppatil/Downloads/node1/bin:~/Downloads/node1/lib:~/Downloads/node1/include:~/Downloads/node1/share
