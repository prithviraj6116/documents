@echo off
ls  > C:\Users\ppatil\Downloads\cronLogs\ls1.log 2>&1



cd /d Z:\29\ppatil.sbbug1
sbbackup -opened >> C:\Users\ppatil\Downloads\cronLogs\sbbug1_sbbackup.log 2>&1
cd /d Z:\29\ppatil.tp1
mw sbs clone discard ppatil.sbbug1 -f >> C:\Users\ppatil\Downloads\cronLogs\sbbug1_sbdiscard.log 2>&1



cd /d Z:\50\ppatil.sbl1
sbbackup -opened
cd /d Z:\50\ppatil.sbl1
mw sbs clone discard ppatil.sbl1
cd /d Z:\50
mw -using Bllvm sbs clone create -cluster Bllvm -name "sbl1"
cd /d Z:\50\ppatil.sbl1
sbrestore --no-prompt -f





cd /d Z:\29\ppatil.sbbug1
sbprepare
sbvisual -ibuild ppatil.sbbug1.sln > C:\Users\ppatil\Downloads\cronLogs\sbbug1_sbvisualIbuild.log 2>&1

cd /d Z:\50\ppatil.sbl1
sbmake CTB="stateflow_resources stateflow stateflow_core"
