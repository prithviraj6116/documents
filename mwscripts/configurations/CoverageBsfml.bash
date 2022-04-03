#!/bin/bash
. /hub/share/sbtools/bash_setup.bash;
testDir=matlab/test/toolbox/stateflow/sf_in_matlab
USER1=ppatil
USER2=ppatil
FILELISTComplete=CoverageSFinML.txt
FILELISTLimited=CoverageSFinML.txt

sbsNameCN=null
sbsNameFILESLimited=null
sbsNameFILESComplete=null

runCoverage()
{
    dateNow=`date +%y%m%d%H%M%S`;
    sbsName=Bsfmlcoverage_$dateNow
    mw -using Bsfml sbs clone create -c Bsfml -n "$sbsName";
    cd $s/$sbsName;


    allJobs=`p4 jobs //mw/Bsfml/... | grep -i 2019`    
    #allJobs=`p4 jobs //mw/Bsfml/...`    
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
    latestChangeNo=`cat /mathworks/devel/bat/Bsfml/logs/$jobLatestNumberWithoutJs/change_level`
    previousChangeNo=`cat /mathworks/devel/bat/Bsfml/logs/$jobPreviousNumberWithoutJs/change_level`

    if [[ $1 == "cn" ]]; then
        sbsNameCN=$sbsName;
        sbmcovsetupargs=" ";
        changeNo=$((0));
        changesInLatestJobs=`p4 changes -m30 //mw/Bsfml/...` #@$dateOfJobPrevious,@$now`
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
        sbmcovsetup -disable
        sbmcovsetup $sbmcovsetupargs
        echo "starting sbruntests"
        mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/18/Bsfml.$jobPrevious.sb" -runallunder $testDir  -unbp g1959164  
        sbmcovsetup -disable
        sleep 600
    elif [[ $1 == "filesLimited" ]]; then
        sbsNameFILESLimited=$sbsName;
        echo "starting sbmcovsetup with sbmcovsetup -cover $FILELISTLimited"
        rm CoverageSFinML.txt;
        find matlab/toolbox/matlab/codetools/+matlab/+codetools/+internal/ -name "sfxfile.m" >> CoverageSFinML.txt;
        find matlab/toolbox/stateflow/stateflow/+Stateflow/+App/+Studio -name "*m" >> CoverageSFinML.txt;
        find matlab/toolbox/stateflow/stateflow/+Stateflow/+App/+Cdr -name "*m" >> CoverageSFinML.txt;
        find matlab/toolbox/shared/stateflow -name "*m" >> CoverageSFinML.txt;
        sbmcovsetup -disable
        sbmcovsetup -cover $FILELISTLimited
        echo "starting sbruntests"
        mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/18/Bsfml.$jobPrevious.sb" -runallunder $testDir -unbp g1959164 
        sbmcovsetup -disable
        sleep 600
    elif [[ $1 == "filesComplete" ]]; then
        sbsNameFILESComplete=$sbsName;
        echo "starting sbmcovsetup with sbmcovsetup -cover $FILELISTComplete"
        sbmcovsetup -disable
        sbmcovsetup -cover $FILELISTComplete
        echo "starting sbruntests"
        mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/18/Bsfml.$jobPrevious.sb" -runallunder $testDir -unbp g1959164 
        sbmcovsetup -disable
        sleep 600
    else
        echo "wrong argument to runCoverage"
    fi
}


mailToMe()
{
        mail -s "Bsfml coverage report for Bsfml.$jobLatest "  $1@mathworks.com<<EOF

        Report CHANGED Files: $2
        ChangeLists: $sbmcovsetupargs
        Reproduction Commands:
                  mw -using Bsfml sbs clone create -c Bsfml.$jobLatest -n "r1_$sbsName";
                  cd /mathworks/devel/sandbox/<youruserid>/r1_$sbsName
                  sbmcovsetup $sbmcovsetupargs
                  mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/18/Bsfml.$jobPrevious.sb" -runallunder $testDir;


        Report Limited Set: $3
        FileList: $FILELISTLimited
        Reproduction Commands:
                  mw -using Bsfml sbs clone create -c Bsfml.$jobLatest -n "r2_$sbsName";
                  cd /mathworks/devel/sandbox/<youruserid>/r2_$sbsName
                  sbmcovsetup -cover "$FILELISTLimited"
                  mw sbruntests -sbmcovsummary-args="-diff /mathworks/devel/sbs/18/Bsfml.$jobPrevious.sb" -runallunder $testDir;

EOF
  
}





#runCoverage "cn"
runCoverage "filesLimited"
#runCoverage "filesComplete"
#sbsName1="http://$USER-deb9-64.dhcp.mathworks.com/mathworks/devel/sbs/18/$USER.$sbsNameCN/work/sbruntests/glnxa64/sbtest/mcovsummary/index.html"
sbsName2="http://$USER-deb9-64.dhcp.mathworks.com/mathworks/devel/sbs/18/$USER.$sbsNameFILESLimited/work/sbruntests/glnxa64/sbtest/mcovsummary/index.html"
#sbsName3="http://$USER-deb9-64.dhcp.mathworks.com/mathworks/devel/sbs/18/$USER.$sbsNameFILESComplete/work/sbruntests/glnxa64/sbtest/mcovsummary/index.html"
mailToMe $USER1 $sbsName1 $sbsName2 $sbsName3
mailToMe $USER2 $sbsName1 $sbsName2 $sbsName3



