#!/bin/bash

#Note 1: Do not delete any lines below.
#        Leave environment variable empty if not required.
#        reset enviornment variable by giving empty string '' and NOT by giving '0' or 0
#        semi-comma is MUST at the end of each line
#Note 2: logs will created in $s/qualificationLogs
#Note 3:qualification reproducation script will be in $s/qualificationLogs/$name/sbqualify.bash
#       you can use above script to produce identical qualification anytime




export name='sfx602';


# '1':to clone new sandbox;
# '' :  to use existing sandbox of above $name
export sbclone='';

#cluster
export sbcluster='Bsfml';


#job number without j. leave empty for latest_pass. It is ignored if sbclone=''.
export sbclonefromspecificjob=''; #1005580'; #897435';

#restorepoint directory,
#CAUTION/DANGER: if specified with sbclone='' (i.e. use existing sandbox), all existing changes in sandbox will be p4 reverted.

export rp=''; #/sandbox/ppatil/_sbbackup/sbs_ppatil.lcmdacore2_1_backup/v1/';
#export rp='/sandbox/ppatil/_sbbackup/local_ppatil-deb9-64_local-ssd_ppatil_m2_backup/v1/';
#export rp=''; #/sandbox/ppatil/_sbbackup/z3/mcosOff';

#changelists to be  synced after cloning without c seperated by space
export p4syncchangelists=''; #3775763 3776471 3776770 3778446 3771769 3771992'; 


#lcm double update; changelists separated by space
#specifying this enables sbclone='1', sbclonefromspecificjob='', rp='',  and sbcluster="Blcmdacore2"
export lcm2update='';


#compile components CTB list
export ctb='';
export ctb="$ctb stateflow_sf_in_matlab_tests stateflow_matlab_runtime stateflow stateflow_core stateflow_matlab_runtime sf4ml_testtools stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sflint_tests stateflow_sfx_demos"
#export ctb="$ctb matlab_resources stateflow_matlab_runtime stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sfx_demos"
#export ctb="$ctb sf4ml_testtools";
#export ctb="$ctb stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests";
#export ctb="$ctb stateflow_sf_in_matlab_install_tests stateflow_sf_in_matlab_tests";

#export ctb="$ctb sf_cdr sf_xform sf_ir stateflow_core stateflow stateflow_demos stateflow_resources simulink_core";
#matlab_resources stateflow_sfx_demos stateflow_matlab_runtime";

#export ctb="$ctb matlab_resources stateflow_resources"
#export ctb="$ctb stateflow_core stateflow_matlab_runtime"
#export ctb="$ctb stateflow_core simulink_core stateflow_resources"

#export ctb="$ctb stateflow_matlab_runtime stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests";

#export ctb="$ctb services";


#export ctb="$ctb stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_matlab_runtime";
#fast
#export ctb="$ctb services sfeml_testtools stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_matlab_runtime stateflow_sfx_demos";
#export ctb="$ctb";

#export ctb="$ctb stateflow stateflow_resources stateflow_tests stateflow_coder_semantics_tests"; 
#medium
#export ctb="$ctb stateflow_core stateflow stateflow_resources";
#slow
#export ctb="$ctb stateflow_demos stateflow_demos_tests slglue"; 
#temporary
#export ctb="$ctb shared_dastudio eml_java simulink_core matlab_resources shared_dastudio_builtins"; 
#export ctb="$ctb simulink_core matlab_toolbox_helptools"; 
#export ctb="$ctb stateflow_core_testtools slstart_tests simulink sltemplate demotools"; 
#export ctb="$ctb stateflow_core_testtools stateflow_demos_license_tests"
#export ctb="$ctb matlab_resources stateflow_core stateflow stateflow_sf_in_matlab_tests stateflow_sf_in_matlab_install_tests stateflow_sfx_demos"

#sbsbmartbuild '1' for yes; '' for no
export smartbd='';


# sbrunlikebat
#testlists (space separated if multiple) path relative to matlabroot
export testlist=''; #test/toolbox/stateflow/sf_in_matlab/cdr/positive/tWorkflowTests_3.m';

#same as testlist in the case when test is BPed
export unbp='';
#export unbp='g2080059 -unbp g2080061';
#export unbp='test/toolbox/stateflow/sf_in_matlab/code_generation/debugging/tDebuggingBasic.m -unbp test/toolbox/stateflow/sf_in_matlab/conditional_breakpoints/tAdvanced_Multi_instance.m  -unbp test/toolbox/stateflow/sf_in_matlab/bug_fixes/tg1879447_ChartUnlockedAfterDebugging.m'
# for sbruntests
export cfg=''; #/mathworks/home/ppatil/Downloads/debug1/failed_testsuites.txt';
export selector='MACRO(tsf_in_ml)'; #CTB_TESTS_ALSO_IN(Bcoderuk)';
#export runallunder='test/toolbox/stateflow/'; 
#export runallunder='test/toolbox/stateflow/sf_in_matlab';
#export runallunder='test/toolbox/stateflow/sf_in_matlab -runallunder test/toolbox/matlab/general/debugger';
export sbmcoverage='';
export testsuites='';
#export testsuites='dacore -testsuites Acgir';
#export ctb='simulink_core stateflow_core';




#Do not change anything below
export originalQualifyBash=1;

bash /mathworks/devel/sandbox/ppatil/misc/configurations/qualifyHelper.bash

