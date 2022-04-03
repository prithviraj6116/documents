#!/bin/bash

#Note 1: Do not delete any lines below.
#        Leave environment variable empty if not required.
#        reset enviornment variable by giving empty string '' and NOT by giving '0' or 0
#        semi-comma is MUST at the end of each line
#Note 2: logs will created in $s/qualificationLogs
#Note 3:qualification reproducation script will be in $s/qualificationLogs/$name/sbqualify.bash
#       you can use above script to produce identical qualification anytime




export name='q3_rtw_extrinsic_2';


# '1':to clone new sandbox;
# '' :  to use existing sandbox of above $name
export sbclone='';

#cluster
export sbcluster='Bstateflow';


#job number without j. leave empty for latest_pass. It is ignored if sbclone=''.
export sbclonefromspecificjob=''; #1005580'; #897435';

#restorepoint directory,
#CAUTION/DANGER: if specified with sbclone='' (i.e. use existing sandbox), all existing changes in sandbox will be p4 reverted.

export rp=''; #/sandbox/ppatil/_sbbackup/sbs_ppatil.lcmdacore2_1_backup/v1/';
#export rp='/sandbox/ppatil/_sbbackup/local_ppatil-deb9-64_local-ssd_ppatil_sf1_backup/v1/';
#export rp=''; #/sandbox/ppatil/_sbbackup/z3/mcosOff';

#changelists to be  synced after cloning without c seperated by space
export p4syncchangelists=''; #3775763 3776471 3776770 3778446 3771769 3771992'; 


#lcm double update; changelists separated by space
#specifying this enables sbclone='1', sbclonefromspecificjob='', rp='',  and sbcluster="Blcmdacore2"
export lcm2update='';


#compile components CTB list
#export ctb='cgir_core stateflow_core cgir_support autosar_tests simulink_lookuptable_blocks_tests';
#export ctb='stateflow_core stateflow_resources stateflow_coder_customcode_tests';
export ctb='sf4ml_testtools stateflow_matlab_runtime stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sf_in_matlab_deploy_tests stateflow_sflint_tests'; #stateflow_core stateflow_bus_tests'; # stateflow_resources stateflow_coder_customcode_tests';
#export ctb='stateflow_core stateflow_resources';
export ctb='stateflow_core';
export ctb='';
#export ctb='matlab_resources stateflow_matlab_runtime stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sf_in_matlab_deploy_tests stateflow_sflint_tests';
#export ctb='stateflow_resources stateflow_thiskeyword_tests';

#sbsbmartbuild '1' for yes; '' for no
export smartbd='1';

# sbrunlikebat
#testlists (space separated if multiple) path relative to matlabroot
export testlist=''; #test/toolbox/stateflow/sf_in_matlab/cdr/positive/tWorkflowTests_3.m';
#export macro='tsf_in_ml'; #test/toolbox/stateflow/sf_in_matlab/cdr/positive/tWorkflowTests_3.m';

#same as testlist in the case when test is BPed
export unbp=''; #g2466224'; #g2292966'
# for sbruntests
export cfg='/home/ppatil/Downloads/failed5.txt';
export cfg=''; #/home/ppatil/Downloads/failed91.txt';
#export cfg='/home/ppatil/Downloads/debug1/failed41.txt';
export selector=''; #dummy'; #MACRO(tsf_in_ml)'; #CTB_TESTS_ALSO_IN(Bcoderuk)';
export unbp2=''; #g2501131'; #g2501131 -unbp g2501114 -unbp g2501288  -unbp g2501301'; #g2466224'; #g2292966'
export runallunder=''; #test/toolbox/stateflow -runallunder test/toolbox/coder/simulink ';
export runallunder='test/toolbox/stateflow/thiskeyword'; #coder/customcode -runallunder test/toolbox/stateflow/bus -runallunder test/toolbox/stateflow/errors -runallunder test/toolbox/rtw/targets/ert/rowmajor/stateflow';
export sbmcoverage='';
export testsuites='';
export testsuites='sfcore';
#export testsuites='sfcore -testsuites Acgir -testsuites dacore';




#Do not change anything below
export originalQualifyBash=1;

bash /mathworks/devel/sandbox/ppatil/misc/configurations/qualifyHelper.bash


