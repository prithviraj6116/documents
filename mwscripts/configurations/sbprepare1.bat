@ECHO OFF
REM Find the root of the current sandbox.
for /f "tokens=*" %%i in ('sbroot') do set sbrootDir=%%i
echo Using sandbox: %sbrootDir%

cd "%sbrootDir%"

REM Create a .gitignore file that will ignore the solution and project files generated by nativeproj for the current sandbox.
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
echo %CurrentDirName%.sdf>>.gitignore
echo %CurrentDirName%.sln>>.gitignore
echo %CurrentDirName%.suo>>.gitignore
REM Also, set the .gitignore file in read-only mode to ease the non submission of this file.
attrib +r .gitignore

echo Create a fastbuild file for the Stateflow code base to enable bundle build using nativeproj.
echo touch matlab\toolbox\stateflow\src\stateflow\vcproj.defn.fastbuild
echo attrib +r matlab\toolbox\stateflow\src\stateflow\vcproj.defn.fastbuild

REM call sbnativeproj -nobb src/services:nopch:notest

REM call sbnativeproj -nobb toolbox/stateflow/src/stateflow:notest toolbox/stateflow/src/sf_editor:notest src/cg_ir:nopch:notest src/mcos_impl:nopch:notest src/m_dispatcher:nopch:notest src/dastudio_platform:nopch:notest src/m_lxe:nopch:notest toolbox/stateflow/src/sfdi_datamodel toolbox/stateflow/src/sfdi_datamodel_mi

REM call sbnativeproj -nobb toolbox/stateflow/src/stateflow:notest toolbox/stateflow/src/sf_runtime:notest src/cg_ir:nopch:notest toolbox/stateflow/src/sf_cdr:notest toolbox/stateflow/src/sf_xform toolbox/stateflow/src/sf_sfun:notest toolbox/stateflow/src/sf_xform_driver:notest

REM call sbnativeproj -nobb -no3p toolbox/stateflow/src/stateflow:notest src/cg_ir:nopch:notest toolbox/stateflow/src/sf_runtime:notest
call sbnativeproj toolbox/stateflow/src/stateflow:no-test 

REM call sbnativeproj -nobb -no3p toolbox/stateflow/src/stateflow:notest src/cg_ir:nopch:notest toolbox/stateflow/src/sf_runtime:notest src/cgir_xform:nopch:notest src/cgir_support:nopch:notest

REM call sbnativeproj -nobb toolbox/stateflow/src/stateflow:notest src/cg_ir:nopch:notest toolbox/stateflow/src/sf_runtime:notest src/cgir_xform:notest

REM call sbnativeproj -nobb toolbox/stateflow/src/stateflow:notest toolbox/stateflow/src/sf_runtime:notest src/cg_ir:nopch:notest src/cgir_cgel:notest src/simulink:notest src/cgir_xform:notest src/SimulinkBlock:notest src/sl_lang_blocks:notest src/sl_engine_classes:notest src/sl_compile:notest

REM call sbnativeproj -nobb toolbox/stateflow/src/stateflow:notest src/cg_ir:nopch:notest src/cgir_cgel:notest src/simulink:notest src/cgir_xform:notest src/SimulinkBlock:notest src/sl_event_blocks:notest src/sl_lang_blocks:notest src/sl_engine_classes:notest

echo Finished generating projects.

REM Cannot have src/m_interpreter now...

echo Now fixing the solution

sed "/^$/d" %CurrentDirName%.sln > temp.tmp
mv temp.tmp %CurrentDirName%.sln

REM echo Compile the solution!
REM C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe %CurrentDirName%.sln

rm -f matlab\bin\win64\*.pdb

echo Finished preparing sandbox.


