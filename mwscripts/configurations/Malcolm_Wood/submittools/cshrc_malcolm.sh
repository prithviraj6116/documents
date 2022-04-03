#!/bin/csh -f

alias dmb sbmake -distcc build DEBUG=1
alias smb sbmake build DEBUG=1
alias smbv sbmake build DEBUG=1 VERBOSE=1
alias smp sbmake prebuild

alias smbc sbmake -o maven_bom DEBUG=1 COMPONENTS_TO_BUILD=\!:1
alias dmbc sbmake -distcc -o maven_bom DEBUG=1 COMPONENTS_TO_BUILD=\!:1

alias sbccc sbcc -dc \!:1
alias sbed sbedits -d .

alias cds cd /sandbox/mwood
alias cdlatest cd /mathworks/devel/jobarchive/\!:1/latest_pass
alias cdbuild cd \`mw -using Bslx:current anchor\`

alias srcdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/src/simulink\`
alias slsdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/src/sl_loadsave\`
alias slsmdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/toolbox/simulink/sl_loadsave_mcos/src/sl_loadsave_mcos\`
alias sgcdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/src/sl_graphical_classes\`
alias tbdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/toolbox/simulink/simulink\`
alias testdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/test/toolbox/simulink\`
alias resdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/resources/Simulink/en\`
alias jdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/java/src\`
alias shcdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/toolbox/simulink/simharness/src/simharness_core\`
alias shdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/toolbox/shared/simharness/src/simharness\`
alias incdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/derived/glnxa64/src/include\`
alias csdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/toolbox/shared/configset/src/configset_base\`
alias sltdir cd \`/public/Malcolm_Wood/submittools/cdhelper_python matlab/toolbox/simulink/sltemplate/web/GalleryView/js/app\`

alias sbdir cd \`sbroot\`

alias sbrt /public/Malcolm_Wood/submittools/sbruntests_results

alias msbscanlog sbscanlog -ohtml-and-view sbtest/sbscanlog_results.html

alias scsh source /home/mwood/.cshrc.mine
alias ecsh sbe /public/Malcolm_Wood/submittools/cshrc_malcolm.sh

alias econfig e -w matlab/config/components/\!:1 \&
alias compgrep find matlab/config/components -name \\*.xml -exec grep -n -H \!:1 {} \\\;

alias mgrep find . -name \"*.m\" -exec grep -n -H \!:1 '{}' \\\;
alias xgrep find . -name \"*.cpp\" -exec grep -n -H \!:1 '{}' \\\;
alias jgrep find . -name \"*.java\" -exec grep -n -H \!:1 '{}' \\\;
alias hgrep find . -name \"*.hpp\" -exec grep -n -H \!:1 '{}' \\\;
alias hgrepx find . -name \"*.h\" -exec grep -n -H \!:1 '{}' \\\;
alias egrep find . -name \"*\!:2\" -exec grep -n -H \!:1 '{}' \\\;
alias xgrepc xgrep \!:1 \| grep -c \!:1
alias hgrepc hgrep \!:1 \| grep -c \!:1
alias jsgrep find . -name \"*.js\" -exec grep -n -H \!:1 '{}' \\\;
alias msb sb -nosplash -nodesktop -noaccel

alias ecrash e ~/matlab_crash_dump.\!:1\-1
alias tcrash /sandbox/mwood/stack_decoder.pl --in=/home/mwood/matlab_crash_dump.\!:1 --format=short

alias msbruntests sbruntests -local all -F none -testsuites \!:1 -rerunusing jobarchive
alias msbruntestsn sbruntests -local all -F none -testsuites \!:1 -noretryfailedtests -rerunusing nothing
alias msbruntestsf sbruntests -autofarm -F none -testsuites \!:1 -rerunusing jobarchive
alias msbruntestsq sbruntests -local all -F none -testsuites Bslx_short -noretryfailedtests -rerunusing nothing
alias msbruntestsqf sbruntests -autofarm -F none -testsuites Bslx_short -rerunusing jobarchive
alias msbruntests_rerun sbruntests -local all -F none -testsuites ../Bslx\!:1_sbruntests/glnxa64\!:2/sbtest/failed_testsuites.txt -rerunusing jobarchive

setenv P4CONFIG .perforce

alias sbsnew mw -using \!:1 sbs clone create -cluster \!:1
alias sbsdiscard mw sbs discard .

alias p4c p4 changes -u mwood -s pending

alias chrome /opt/google/chrome/chrome
alias chromed /opt/google/chrome/chrome http://localhost:49431/ \&
