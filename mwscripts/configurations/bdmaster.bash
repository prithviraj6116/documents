#!/bin/bash

# note 1: do not delete any line below.
# note 2: leave environment variable empty if not required i.e. var='';
# note:3: all logs are created in $s/bdmasterLogs/
# note 4: number of processes will be forked equal to the noOfSandboxes value provided below  and this bash script will finish immediately. If you need to kill all the forked processes, use pkill -9 -f bdmasterHelper;pkill -9 -f sbsmartbuild




export name='i4';

export sbcluster="Bstateflow";


#number of parallel sandboxes needed
#e.g: if noOfChanges=16 and noOfSandboxes=3
#sandbox1: change1 synched then build. change#2 synced then built. change#3 synched then build and so  on till changes6
#sandbox2: change1-change6 are synched but not built immediately. then change#7 synched then build. then change#8 synched then built till change#12
#sandbox3: change1-change12 are synched but not built immediately. then change#13 synched then build. then change#14 synched then built till change#16
#note: change#1 is the first/earliest changelist in the current running job.
export noOfSandboxes=2;


#number of changelist steps to take per build cycle
#e.g. using same above example with noOfChanges=16 and noOfSandboxes=3 and noOfChangelistSteps=2,
#sandbox1: change1+change2 synched then buil. change3+change4 synched then build and so  on till changes6
#sandbox2: change1-change6 are synched but not built immediately. then change#7+chagne#8 synched then build. then change#9+change10 synched then built. and so on  till change#12
#sandbox3: change1-change12 are synched but not built immediately. then change#13 +change14 synched then build. an so on.
#note: change#1 is the first/earliest changelist in the current running job.
export noOfChangelistSteps=3;


export ctb='stateflow';

#noOfChanges to process from the ::LKG
#by default (i.e. if 0) all the changes from ::LKG to now are processed
#you can give a number between 1 to all changes in the current job
#e.g. if there are 17 changes in current job and if you give value 10
#then we will only build/test till the 10th change from the LKG and remaining 7 will
#not be processed
export noOfChanges=0;


export testlist='test/toolbox/stateflow/coder/semantics/duration/negative/tGraphicalFcnInDuration.m';





#do not change anything below
export qeGateKeeper=''
bash /mathworks/devel/sandbox/ppatil/configurations/bdmasterHelper.bash

