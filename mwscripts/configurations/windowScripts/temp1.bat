cd C:\Users\ppatil\Downloads
call :ls21 ls22  
:ls21
ls >> C:\Users\ppatil\Downloads\cronLogs\"%1".log 2>&1



call :sbbackupFun %1 %2 %3 %4 "%5"
call :sbdiscardFun %1 %2 %3 %4 "%5"
call :sbcloneFun %1 %2 %3 %4 "%5"
call :sbrestoreFun %1 %2 %3 %4 "%5"
call :sbprepareFun %1 %2 %3 %4 "%5"
call :sbmakeFun  %1 %2 %3 %4 "%5"

call sbbackupFun sbbug1 Bstateflow 29 ppatil
call sbdiscardFun sbbug1 Bstateflow 29 ppatil
call sbcloneFun sbbug1 Bstateflow 29 ppatil
call sbrestoreFun sbbug1 Bstateflow 29 ppatil
call sbprepareFun sbbug1 Bstateflow 29 ppatil
call sbmakeFun sbbug1 Bstateflow 29 ppatil
