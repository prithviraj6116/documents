#!/bin/bash
. /hub/share/sbtools/bash_setup.bash;
testDir=matlab/test/toolbox/stateflow/sf_in_matlab
USER1=ppatil
USER2=ppatil
FILELISTComplete=/mathworks/devel/sandbox/$USER1/misc/configurations/bllvmSF4MLFilesForCodeCoverageCompleteSet.txt
FILELISTLimited=/mathworks/devel/sandbox/$USER1/misc/configurations/bllvmSF4MLFilesForCodeCoverageLimitedSet.txt
sbsNameCN=null
sbsNameFILESLimited=null
sbsNameFILESComplete=null

runCoverage()
{
    dateNow=`date +%y%m%d%H%M%S`;
    sbsName=bllvmcoverage_$dateNow
    mw -using Bllvm sbs clone create -c Bllvm -n "$sbsName";
    cd $s/$sbsName;


    allJobs=`p4 jobs //mw/Bllvm/... | grep -i 2019`    
    #allJobs=`p4 jobs //mw/Bllvm/...`    
    while read -r line; do
        arrChanges=("$line" "${arrChanges[@]}")
    done <<< "$allJobs"
    tokens=( ${arrChanges[0]} );
    jobLatest=${tokens[0]};
    #jobLatest=j955311;
    dateOfJobLatest=${tokens[2]};
    tokens=( ${arrChanges[1]} );
    jobPrevious=${tokens[0]};
    #jobPrevious=j954915;
    dateOfJobPrevious=${tokens[2]};
    jobLatestNumberWithoutJs=$(echo $jobLatest|cut -d'j' -f 2)
    jobPreviousNumberWithoutJs=$(echo $jobPrevious|cut -d'j' -f 2)
    latestChangeNo=`cat /mathworks/devel/bat/Bllvm/logs/$jobLatestNumberWithoutJs/change_level`
    previousChangeNo=`cat /mathworks/devel/bat/Bllvm/logs/$jobPreviousNumberWithoutJs/change_level`

    if [[ $1 == "cn" ]]; then
        sbsNameCN=$sbsName;
        sbmcovsetupargs=" ";
        changeNo=$((0));
        changesInLatestJobs=`p4 changes -m30 //mw/Bllvm/...` #@$dateOfJobPrevious,@$now`
        while read -r line; do
            changeNo=$((changeNo+1))
            arrChanges=("$line" "${arrChanges[@]}")
        done <<< "$changesInLatestJobs"
        noOfChanges=${#arrChanges[@]}

        sbmcovsetupargs=" "
        started="no"
        for ((i=0; i<changeNo; i++));do
            tokens=( ${arrChanges[i]} );
            changelistNumber=${tokens[1]};
            echo $changelistNumber
            if [[ $previousChangeNo == $changelistNumber ]]; then
                started="yes"
            elif [[ $latestChangeNo == $changelistNumber ]]; then
                echo adding "$changelistNumber to coverage report as it is part of $jobLatest"
                sbmcovsetupargs="$sbmcovsetupargs -cn $changelistNumber"
                started="no"
            elif [[ $started == "yes" ]]; then
                started="yes"
                echo adding "$changelistNumber to coverage report as it is part of $jobLatest"
                sbmcovsetupargs="$sbmcovsetupargs -cn $changelistNumber"
            else
                started="no"
                echo skipping "$changelistNumber     as it is not part of this job $jobLatest"
            fi
        done
        echo "starting sbmcovsetup with sbmcovsetup $sbmcovsetupargs"
        sbmcovsetup $sbmcovsetupargs
    elif [[ $1 == "filesLimited" ]]; then
        sbsNameFILESLimited=$sbsName;
        echo "starting sbmcovsetup with sbmcovsetup -cover $FILELISTLimited"
        sbmcovsetup -cover $FILELISTLimited
    elif [[ $1 == "filesComplete" ]]; then
        sbsNameFILESComplete=$sbsName;
        echo "starting sbmcovsetup with sbmcovsetup -cover $FILELISTComplete"
        sbmcovsetup -cover $FILELISTComplete
    else
        echo "wrong argument to runCoverage"
    fi
    echo "starting sbruntests"
    mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/50/Bllvm.$jobPrevious.sb -dirview" -runallunder $testDir -unbp g1922971
    sbmcovsetup -disable
    sleep 600
}


mailToMe()
{
        mail -s "Bllvm coverage report for Bllvm.$jobLatest "  $1@mathworks.com<<EOF

        Report CHANGED Files: $2
        ChangeLists: $sbmcovsetupargs
        Reproduction Commands:
                  mw -using Bllvm sbs clone create -c Bllvm.$jobLatest -n "r1_$sbsName";
                  cd /mathworks/devel/sandbox/<youruserid>/r1_$sbsName
                  sbmcovsetup $sbmcovsetupargs
                  mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/50/Bllvm.$jobPrevious.sb -dirview" -runallunder $testDir;


        Report Limited Set: $3
        FileList: $FILELISTLimited
        Reproduction Commands:
                  mw -using Bllvm sbs clone create -c Bllvm.$jobLatest -n "r2_$sbsName";
                  cd /mathworks/devel/sandbox/<youruserid>/r2_$sbsName
                  sbmcovsetup -cover "$FILELISTLimited"
                  mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/50/Bllvm.$jobPrevious.sb -dirview" -runallunder $testDir;

        Report Complete Set: $4
        FileList: $FILELISTComplete
        Reproduction Commands:
                  mw -using Bllvm sbs clone create -c Bllvm.$jobLatest -n "r3_$sbsName";
                  cd /mathworks/devel/sandbox/<youruserid>/r3_$sbsName
                  sbmcovsetup -cover "$FILELISTComplete"
                  mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/50/Bllvm.$jobPrevious.sb -dirview" -runallunder $testDir;
EOF
  
}
runCoverage "cn"
runCoverage "filesLimited"
#runCoverage "filesComplete"
sbsName1="http://$USER-deb9-64.dhcp.mathworks.com/mathworks/devel/sbs/50/$USER.$sbsNameCN/work/sbruntests/glnxa64/sbtest/mcovsummary/index.html"
sbsName2="http://$USER-deb9-64.dhcp.mathworks.com/mathworks/devel/sbs/50/$USER.$sbsNameFILESLimited/work/sbruntests/glnxa64/sbtest/mcovsummary/index.html"
#sbsName3="http://$USER-deb9-64.dhcp.mathworks.com/mathworks/devel/sbs/50/$USER.$sbsNameFILESComplete/work/sbruntests/glnxa64/sbtest/mcovsummary/index.html"
mailToMe $USER1 $sbsName1 $sbsName2 $sbsName3
mailToMe $USER2 $sbsName1 $sbsName2 $sbsName3



