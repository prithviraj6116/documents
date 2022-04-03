#!/bin/bash
last_snap_LKG_bdacore_integ=j761238
filesWithConflicts='
//mw/Bstateflow/matlab/toolbox/stateflow/src/stateflow/cdr/cdr_semantics_state.cpp
'
pdbOld='';
pdbNew='.pdb';





if [ -n "$1" ]; then
    mw sbs clone discard ppatil.snapMergeNew.pdb ppatil.snapMergeOld.pdb ppatil.snapMergeOld ppatil.snapMergeNew;
    mw -using Bdacore_integ sbs clone create -cluster Bdacore_integ -name "snapMergeNew";
    mw -using Bdacore_integ sbs clone create -cluster Bdacore_integ.$last_snap_LKG_bdacore_integ -name "snapMergeOld"
    exit
elif [ -n "$2" ]; then
    echo "set pdb accordingly";
else
    mw sbs clone discard ppatil.snapMergeNew$pdbNew;
    mw sbs clone discard ppatil.snapMergeOld$pdbOld;
    mw -using Bdacore_integ sbs clone create -cluster Bdacore_integ -name "snapMergeNew";
    mw -using Bdacore_integ sbs clone create -cluster Bdacore_integ.$last_snap_LKG_bdacore_integ -name "snapMergeOld"
fi


sandboxFiles="${filesWithConflicts//\/\/mw\/Bstateflow\//}"
sandboxFiles="${sandboxFiles// /}"
echo $filesWithConflicts


SAVEIFS=$IFS
# Change IFS to new line. 
IFS=$'\n'
names=($sandboxFiles)
# Restore IFS
IFS=$SAVEIFS



cd $s/snapMergeOld$pdbOld;
gvim $sandboxFiles 
#echo "abc"
#p4v . & 
for (( i=0; i<${#names[@]}; i++ ))
do
    meld $s/snapMergeOld$pdbOld/"${names[$i]}" $s/snapMergeNew$pdbNew/"${names[$i]}" &
done

