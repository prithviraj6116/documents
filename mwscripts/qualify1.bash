#!/bin/bash

#Note 1: Do not delete any lines below.
#        Leave environment variable empty if not required.
#        reset enviornment variable by giving empty string '' and NOT by giving '0' or 0
#        semi-comma is MUST at the end of each line
#Note 2: logs will created in $s/qualificationLogs
#Note 3:qualification reproducation script will be in $s/qualificationLogs/$name/sbqualify.bash
#       you can use above script to produce identical qualification anytime




export name='collect_extrinsics_q1';
export name='test_smart1';

# '1':to clone new sandbox;
# '' :  to use existing sandbox of above $name
export sbclone='';

#cluster
export sbcluster='BR2022ad'; 
export sbcluster='Bstateflow';


#job number without j. leave empty for latest_pass. It is ignored if sbclone=''.
export sbclonefromspecificjob=''; 

#restorepoint directory,
#CAUTION/DANGER: if specified with sbclone='' (i.e. use existing sandbox), all existing changes in sandbox will be p4 reverted.

export rp=''; 

#changelists to be  synced after cloning without c seperated by space
export p4syncchangelists=''; 


#lcm double update; changelists separated by space
#specifying this enables sbclone='1', sbclonefromspecificjob='', rp='',  and sbcluster="Blcmdacore2"
export lcm2update='';


#compile components CTB list
#export ctb='cgir_core stateflow_core cgir_support autosar_tests simulink_lookuptable_blocks_tests';
#export ctb='stateflow_core stateflow_resources stateflow_coder_customcode_tests';
export ctb='sf4ml_testtools stateflow_matlab_runtime stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sf_in_matlab_deploy_tests stateflow_sflint_tests'; #stateflow_core stateflow_bus_tests'; # stateflow_resources stateflow_coder_customcode_tests';
export ctb='sfthiskeyword_testtools';
export ctb='';
#export ctb='matlab_resources stateflow_matlab_runtime stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sf_in_matlab_deploy_tests stateflow_sflint_tests';
#export ctb='stateflow_resources stateflow_thiskeyword_tests';

#sbsbmartbuild '1' for yes; '' for no
export smartbd='';

# sbrunlikebat
#testlists (space separated if multiple) path relative to matlabroot
export testlist='';
#export macro='tsf_in_ml';

#same as testlist in the case when test is BPed
export unbp='g2655470'; 
export unbp='';
# for sbruntests
export cfg='/mathworks/home/ppatil/Downloads/failed1.txt';
export cfg=''; 
export selector=''; #dummy'; #MACRO(tsf_in_ml)'; #CTB_TESTS_ALSO_IN(Bcoderuk)';
export unbp2='g2655470'; 
export unbp2=''; 
export runallunder='test/toolbox/stateflow'; 
export runallunder='';
export sbmcoverage='';
export testsuites='sfcore -testsuites Acgir -testsuites dacore';
export testsuites='';
export testsuites='sfcore';



#Do not change anything below
export originalQualifyBash=1;

bash /mathworks/devel/sandbox/ppatil/misc/configurations/qualifyHelper.bash


