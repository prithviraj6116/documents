#!/bin/bash

cd $s/bllvmcoverage_180827120219 
allJobs=`p4 jobs //mw/Bllvm/...`    
while read -r line; do
    arrChanges=("$line" "${arrChanges[@]}")
done <<< "$allJobs"
tokens=( ${arrChanges[0]} );
jobLatest=${tokens[0]};
dateOfJobLatest=${tokens[2]};
tokens=( ${arrChanges[1]} );
jobPrevious=${tokens[0]};
dateOfJobPrevious=${tokens[2]};
changesInLatestJobs=`p4 changes //mw/Bllvm/...@$dateOfJobPrevious,@$dateOfJobLatest`
changeNo=$((0));
while read -r line; do
    changeNo=$((changeNo+1))
    arrChanges=("$line" "${arrChanges[@]}")
done <<< "$changesInLatestJobs"
echo $changeNo
noOfChanges=${#arrChanges[@]}
sbmcovsetup="sbcovsetup "
#echo $noOfChanges
for ((i=0; i<changeNo; i++));do
    tokens=( ${arrChanges[i]} );
    changelistNumber=${tokens[1]};
    isError=`sbmcovsetup -cn $changelistNumber`
    if [[ $isError = *"Error in changelist"* ]]; then
        echo skipping "$changelistNumber     as it is not part of this job $jobLatest"
    else
        echo adding "$changelistNumber to coverage report as it is part of $jobLatest"
        sbmcovsetup="$sbmcovsetup -cn $changelistNumber"
    fi
done
echo $sbmcovsetup
cd -



