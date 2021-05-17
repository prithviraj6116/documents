export ZFS_MASTER_SB="Bstateflow"
export SILENT=1
export LOCATION=AH
export BUILD_SRC_SIMULINK=1
export g=/mathworks/devel/sandbox/ppatil/misc/githubroot/documents
alias q0='gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify.bash';
alias q1='gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify1.bash &';
alias q2='gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify2.bash &';
alias q3='gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify3.bash&';
alias q4='gvim /mathworks/devel/sandbox/ppatil/misc/configurations/qualify4.bash &';
alias sfmlt='go root;cd test/toolbox/stateflow/sf_in_matlab';
alias sfmltt='go root;cd test/tools/sf4ml/+SF4MLTest';
alias sfml='go root; cd toolbox/stateflow/stateflow/+Stateflow/+App';
alias sfmls='go root; cd toolbox/shared/stateflow/';
alias sbr="sb -r \"openExample('stateflow/AutomaticTransmissionUsingDurationOperatorExample');bdclose all;startup; \" &> /tmp/matlab.log &";        
alias sba="go root; cd toolbox/matlab/appdesigner/web/application";        
alias egit="gvim $s/misc/githubroot/documents/dailyLog.tex";
# alias lcpp="cd $s/misc/ContinuousLearning/cpp; gvim exe1/exe1f1.cpp";
alias ljs="cd $s/misc/ContinuousLearning/js; gvim main1.cpp";
alias lc="cd $s/misc/ContinuousLearning/c; gvim main1.cpp";
alias lds="cd $s/misc/ContinuousLearning/distributedsystems; gvim main1.cpp";
alias newSession="cd ~;rm -rf logs log matlab_crash_dump* orig.matlab_crash_dump*; pkill -9 -f matlab;sbstop 8 0;pkill -9 -f chrome;pkill -9 -f p4v;pkill -9 -f gvim;cd -;google-chrome &> /tmp/chrome.log &"
alias newSession1="cd ~;rm -rf logs log matlab_crash_dump* orig.matlab_crash_dump*;cd $s; pkill -9 -f matlab;sbstop 8 0;pkill -9 -f p4v;pkill -9 -f gvim & "
streamName=''

function chdir() {

    if [[ $# == 0 ]];
    then
        export PPP_DIRECTORYNUMBER='-1';
        echo "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
        read -p "Enter directory number: " directoryNumber
        export PPP_DIRECTORYNUMBER=$directoryNumber
    else
        export PPP_DIRECTORYNUMBER=$1
    fi
    #echo "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
    cd "$(perl $d/gitRepo1/pppGitHub/mwscripts/bashrcHelper.pl)"
}

function getStreamName() {
    
    sbverOutput=$(sbver);
    isStreamTag="0";
    IFS=' ' 
    for token in $sbverOutput
    do
        if [[ $isStreamTag == "1" ]];
        then
            streamName=$token
            isStreamTag="0";
        fi
        if [[ $token == Stream:* ]];
        then
            isStreamTag="1";
        fi
    done
    streamName=$(echo "$streamName"|tr '\n' ' ')
    streamName="${streamName/Version: //}"
    streamName="${streamName/ /}"
}
function p4l() {
    getStreamName
    streamName="${streamName//\_/\\_}"
    #streamName=$streamName
    fileNames=''
    p4opened=$(p4 opened);
    IFS=')' 
    for token1 in $p4opened; 
    do 
        if [[ $token1 == *//mwpdb/* ]]
        then
            IFS='#' fileTokens=( $token1 );
            for token2 in $fileTokens; 
            do
                fileName="${token2/$streamName/ }"
                echo $token2
                echo $streamName
                echo $fileName;
                fileNames="$fileNames $fileName"
            done
        fi
    done
    fileNames=$(echo "$fileNames"|tr '\n' ' ')
    editCommand="gvim $fileNames &"
    echo $editCommand
    go root;cd ..
    eval $editCommand

}
function p4n() {
    getStreamName
    fileNames=''
    p4opened=$(p4 opened);
    IFS=')' 
    for token1 in $p4opened; 
    do 
        if [[ $token1 == *//mw/* ]]
        then
            IFS='#' fileTokens=( $token1 );
            for token2 in $fileTokens; 
            do
                fileName="${token2/$streamName/ }"
                fileNames="$fileNames $fileName"
            done
        fi
    done
    fileNames=$(echo "$fileNames"|tr '\n' ' ')
    editCommand="gvim $fileNames &"
    go root;cd ..
    eval $editCommand

}
function g() {
    grep "$@" -iIrn --color=always --exclude=*tags
}
#export PATH=$PATH:/sandbox/dandrade/tools/
export PATH=$PATH:/home/ppatil/Downloads/node1/bin:~/Downloads/node1/lib:~/Downloads/node1/include:~/Downloads/node1/share

function lcpp1 {
cd $s/misc/ContinuousLearning/cpp
menv1="find . -type f \( -iname \"*swp\" -o -iname \"*swo\" -o -iname \"*CMakeCXXCompilerId.cpp\" \) -exec rm {} \; "
eval $menv1
#alias egit="gvim $s/misc/githubroot/documents/dailyLog.tex";
menv2="gvim  $s/misc/githubroot/documents/dailyLog.tex $(grep -irl a  --include=*cpp --include=*hpp .)";
echo $menv2
menv3=$(echo $menv2|tr '\n' ' ');
eval $menv3
}
function gs1 {
menv1="gvim -c \"let @/ = \\\"$1\\\"\" -c \"let @a = \\\"$1\\\"\" $(grep -irl $1 $2 $3 $4 $5 --exclude=*swp --exclude=*swo --exclude=*tags .)";
menv2=$(echo $menv1|tr '\n' ' ');
echo $menv2
eval $menv2
}
function gs2 {
    e="$1.*$2\|$2.*$1";
    e="$1.*$2\\\\\|$2.*$1";
    d1="grep -irPl '(?=.*$1)(?=.*$2)' $3 $4 $5 --exclude=*tags --exclude=*swo --exclude=*swp .";
    echo $d1
    a="gvim +/\"$e\" $(eval $d1)"
    a="gvim -c \"let @a = \\\"$e\\\"\" -c \"let @/ = \\\"$e\\\"\"  $(eval $d1)"
    echo $a
    b=$(echo $a|tr '\n' ' ');
    eval $b
}
function gs3 {
a="gvim $(grep -irl $1 $2 $3  --exclude=*tags .)";
b=$(echo $a|tr '\n' ' ');
eval $b
}
function gs4 {
a="gvim +/$1 $(grep -irl $1 --exclude=*tags .)";eval $a
}
source ~/.bashrc.mine
export VISUAL=gvim
export EDITOR=gvim



