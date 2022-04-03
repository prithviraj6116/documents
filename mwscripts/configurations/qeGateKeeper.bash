#!/bin/bash

# note 1: do not delete any line below.
# note 2;leave environment variable empty if not required.
# note 3: all logs are created in $s/qeGateKeeperLogs/
# note 4: semi-comma is required at the end of each line
# note 4: number of processes will be forked equal to value for noOfParralleProcesses mentioned below. This bash script will exit immediately. If you need to kill all the forked processes, use pkill -9 -f bdmasterHelper

export name='i5';

export sbcluster="Bstateflow"
export sbclusterlocation="39";#39 for Bstateflow,  50 for Bllvm etc.


#runlikebat testpath from matlabroot; separate multiple testpaths with space
export testlist='test/toolbox/stateflow/interface_view/tg1385071_syncMultipleSymbolManagers.m';


#number of parallel processes needed. each process will open a qualifying submission sandbox and run the tests
export noOfParallelProcesses=4;




#CTB if required. separated by space
export ctb='';


#noOfChanges to process from the ::LKG
#by default (i.e. if 0) all the changes from ::LKG to now are processed
#you can give a number between 1 to all changes in the current job
#e.g. if there are 17 changes in current job and if you give value 10
#then we will only build/test till the 10th change from the LKG and remaining 7 will
#not be processed
export noOfChanges=0;



#do not change anything below
export qeGateKeeper='1'
bash /mathworks/devel/sandbox/ppatil/configurations/bdmasterHelper.bash

