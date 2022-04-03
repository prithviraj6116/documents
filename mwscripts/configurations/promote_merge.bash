#!/bin/bash
cd $s/sf1_sbs;
last_promote_LKG_bstateflow=j760932
filesWithConflicts='
 //mw/Bdacore_PP/matlab/toolbox/stateflow/src/sf_cdr/cdr/Chart.cpp
    //mw/Bdacore_PP/matlab/toolbox/stateflow/src/stateflow/cdr/cdr_eml_action_lang.cpp
    //mw/Bdacore_PP/matlab/toolbox/stateflow/src/stateflow/cdr/cdr_eml_propagation.cpp
    //mw/Bdacore_PP/matlab/toolbox/stateflow/src/stateflow/cdr/cdr_semantics_state.cpp
    //mw/Bdacore_PP/matlab/toolbox/stateflow/src/stateflow/cdr/cdr_transform_ml_access.cpp
'
pdbOld='';
pdbNew='';


if [ -n "$1" ]; then
    mw sbs clone discard ppatil.promoteMergeNew.pdb ppatil.promoteMergeOld.pdb ppatil.promoteMergeOld ppatil.promoteMergeNew;
    mw -using Bstateflow sbs clone create -cluster Bstateflow -name "promoteMergeNew";
    mw -using Bstateflow sbs clone create -cluster Bstateflow.$last_promote_LKG_bstateflow -name "promoteMergeOld"
    exit
elif [ -n "$2" ]; then
    echo "set pdb accordingly";
else
    mw sbs clone discard ppatil.promoteMergeNew$pdbNew;
    mw sbs clone discard ppatil.promoteMergeOld$pdbOld;
    mw -using Bstateflow sbs clone create -cluster Bstateflow -name "promoteMergeNew";
    mw -using Bstateflow sbs clone create -cluster Bstateflow.$last_promote_LKG_bstateflow -name "promoteMergeOld"
fi


sandboxFiles="${filesWithConflicts//\/\/mw\/Bdacore_PP\//}"
sandboxFiles="${sandboxFiles// /}"
echo $filesWithConflicts


SAVEIFS=$IFS
# Change IFS to new line. 
IFS=$'\n'
names=($sandboxFiles)
# Restore IFS
IFS=$SAVEIFS



cd $s/promoteMergeOld$pdbOld;
gvim $sandboxFiles 
for (( i=0; i<${#names[@]}; i++ ))
do
    meld $s/promoteMergeOld$pdbOld/"${names[$i]}" $s/promoteMergeNew$pdbNew/"${names[$i]}" &
done

