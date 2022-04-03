function generate_all_headertests(module,force)
% generate_all_headertests
%
% Generates headertest_*.cpp unit test files for all headers listed in
% export/include/<module>/headers.mk

modfolder = fullfile(sbroot,module);
assert(exist(modfolder,'dir')~=0,[modfolder ' not found']);
[~,modname] = fileparts(modfolder);

if modfolder(end)=='/'
    modfolder(end) = [];
end

listfile = fullfile(modfolder,'headerlist.txt');
if ~exist(listfile,'file')
    headers = get_header_list(modfolder,true);
elseif nargin>1 && force
    headers = get_header_list(modfolder,true);
else
    headers = readtextfile(mtfilename(listfile));
end

testfolder = [modfolder '_headertests'];

% Create this folder if it's not there
if exist(testfolder,'dir')==0
    mkdir(testfolder);
end

% Create MODULE_DEPENDENCIES file.
depsfile = fullfile(testfolder,'MODULE_DEPENDENCIES');
i_gen_depsfile(depsfile,modname);

% Create the "unittest" folder if it's not there.
unittest_dir = fullfile(testfolder,'unittest');
if exist(unittest_dir,'dir')==0
    mkdir(unittest_dir);
end

% Create the "suite_registration" file.
suite_reg = fullfile(unittest_dir,'suite_registration.cpp');
i_gen_suite_reg(suite_reg,modname);

headers = headers(~cellfun('isempty',headers));

% Generate a test file for each header.
ht = cell(size(headers));
for i=1:numel(headers)
    h = headers{i};
    [~,headername] = fileparts(h);
    source = fullfile(unittest_dir,[ 'headertest_' sprintf('%.3d',i) '_' strrep(headername,'/','_') '.cpp' ]);
    relheader = fullfile(modname,h);
    try
        src = generate_headertest(relheader,i,source);
        [~,ht{i}] = fileparts(src);
    catch E
        disp(E.message);
    end
end

% Create the Makefile.
makefile = fullfile(testfolder,'Makefile');
i_gen_makefile(makefile,modname,ht);

end

%--------------------------
function i_gen_suite_reg(filename,modname)

f = fopen(filename,'wt');
if f<0
    error('mwood:headertest:fopen','Failed to open: %s',source);
end
closefile = onCleanup(@() fclose(f));

fprintf(f,'// Copyright 2015 The MathWorks, Inc.\n');
fprintf(f,'\n');
fprintf(f,'#include "version.h"\n');
fprintf(f,'#include "test_manager.h"\n');
fprintf(f,'\n');
fprintf(f,'const char* suiteName = "%s_headers";\n',modname);
fprintf(f,'\n');
fprintf(f,'REG_UNIT_TEST_SUITE(suiteName, NULL, NULL)\n');
fprintf(f,'\n');

end

%--------------------------
function i_gen_depsfile(filename,modname)

f = fopen(filename,'wt');
fprintf(f,'%s\n\n',modname);
fclose(f);

end

%--------------------------
function i_gen_makefile(filename,modname,ht)

ht = ht(~cellfun('isempty',ht));
ht = ht(numel(ht):-1:1);

f = fopen(filename,'wt');

fprintf(f,'\n\nCOMPONENT := %s\n\n',modname);

fprintf(f,'OUT_OF_MODEL_no_handwritten_headers := 1\n\n');

fprintf(f,'\ninclude $(MAKE_INCLUDE_DIR)/Makefile.module\n\n');

fprintf(f,'ht_001 : ht_../../derived/glnxa64/obj/src/%s_headertests/unittest/%s.o\n',modname,ht{1});
    fprintf(f,'PHONY: ht_001\n\n');

for i=1:numel(ht)-1
    fprintf(f,'ht_%.3d : ../../derived/glnxa64/obj/src/%s_headertests/unittest/%s.o | ht_%.3d\n',i+1,modname,ht{i+1},i);
    fprintf(f,'PHONY: ht_%.3d\n\n',i+1);
end


fprintf(f,'headertests: ht_%.3d\n\n',numel(ht));

fprintf(f,'\n\n');
fclose(f);



end
