ECHO HELLO WORLD START

call :prepareSB sbbug1 Bstateflow 29 ppatil C:\Users\ppatil\Downloads\cronLogs22 Z:


:prepareSB
net use "%6" \\mathworks\devel\sbs
call :createLogDirs %1 %2 %3 %4 %5
call :sbbackupFun %1 %2 %3 %4 %5
call :sbdiscardFun %1 %2 %3 %4 %5
timeout 100
call :sbcloneFun %1 %2 %3 %4 %5
call :sbrestoreFun %1 %2 %3 %4 %5
call :sbprepareFun %1 %2 %3 %4 %5
call :sbmakeFun  %1 %2 %3 %4 %5
exit /b

:createLogDirs
mkdir "%5"
mkdir "%5"\"%2"
exit /b

:sbbackupFun 
cd /d Z:\"%3"\"%4"."%1" 
sbbackup -opened >> "%5"\"%2"\"%1"_sbbackup.log 2>&1
exit /b

:sbdiscardFun
@ECHO OFF
(
cd /d Z:\"%3"\"%4"."%1" 
call mw -using "%2" sbs clone discard "%4"."%1" -f
)>> "%5"\"%2"\"%1"_sbdiscard.log
exit /b

:sbcloneFun
@ECHO OFF
(
cd /d Z:\"%3" 
call mw -using "%2" sbs clone create -cluster "%2" -name "%1" 
exit /b
)>> "%5"\"%2"\"%1"_sbclone.log 

:sbrestoreFun
@ECHO OFF
(
cd /d Z:\"%3"\"%4"."%1" 
call sbrestore --no-prompt -f 
)>> "%5"\"%2"\"%1"_sbrestore.log 2>&1
exit /b

:sbprepareFun1 
@ECHO OFF
(
cd /d Z:\"%3"\"%4"."%1" 
call sbprepare
)>>"%5"\"%2"\"%1"_sbprepare.log 2>&1
exit /b


:sbmakeFun
@ECHO OFF
(
cd /d Z:\"%3"\"%4"."%1" 
call sbvisual -ibuild "%4"."%1".sln 
)>> "%5"\"%2"\"%1"_sbvisualIbuild.log 2>&1
exit /b


:sbprepareFun 
@ECHO OFF
(
cd /d Z:\"%3"\"%4"."%1" 
for /f "tokens=*" %%i in ('sbroot') do set sbrootDir=%%i
echo Using sandbox: %sbrootDir%
cd "%sbrootDir%"
for %%* in (.) do set CurrentDirName=%%~n*
touch .gitignore
attrib -r .gitignore
echo # Ignore naiveproj Visual Studio generated file. Do not submit this file.>.gitignore
echo native_*.props>>.gitignore
echo native_*.sln>>.gitignore
echo native_*.vcxproj>>.gitignore
echo native_*.vcxproj.filters>>.gitignore
echo native_*.vcxproj.user>>.gitignore
echo native_*.vcxproj.tmp>>.gitignore
echo native_*.vcxproj.filters.tmp>>.gitignore
echo native_*.vcxproj.user.tmp>>.gitignore
echo devenv.cmd>>.gitignore
echo devenv12.cmd>>.gitignore
echo devenv13.cmd>>.gitignore
echo devenv15.cmd>>.gitignore
echo %CurrentDirName%.sdf>>.gitignore
echo %CurrentDirName%.sln>>.gitignore
echo %CurrentDirName%.suo>>.gitignore
attrib +r .gitignore
echo Create a fastbuild file for the Stateflow code base to enable bundle build using nativeproj.
echo touch matlab\toolbox\stateflow\src\stateflow\vcproj.defn.fastbuild
echo attrib +r matlab\toolbox\stateflow\src\stateflow\vcproj.defn.fastbuild
call sbnativeproj -no3p -nobb toolbox/stateflow/src/sf_xform:notest toolbox/stateflow/src/stateflow:notest 
echo Finished generating projects.
echo Now fixing the solution
sed "/^$/d" %CurrentDirName%.sln > temp.tmp
mv temp.tmp %CurrentDirName%.sln
rm -f matlab\bin\win64\*.pdb
echo Finished preparing sandbox.
)>>"%5"\"%2"\"%1"_sbprepare.log 2>&1
exit /b



ECHO HELLO WORLD END