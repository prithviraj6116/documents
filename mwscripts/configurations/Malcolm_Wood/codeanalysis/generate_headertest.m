function source = generate_headertest(relheader,index,source)
% generate_headertest(header)
%
% e.g. in matlab/src/sl_services:
%         generate_headertest sl_services/slsv_exception.hpp
% generates file unittest/headertest_slsv_exception.cpp which verifies
% standalone compilation of file export/include/sl_services/slsv_exception.hpp

is_details = ~isempty(regexp(relheader,'\/details\/','once'));
if is_details
    error('mwood:headertest:details','Skipping "details" header: %s',relheader);
end

is_mock = ~isempty(regexp(relheader,'\/test\/.*Mock.*','once'));
if is_mock
    error('mwood:headertest:details','Skipping "mock" header: %s',relheader);
end

[~,headername] = fileparts(relheader);
if nargin<3 || isempty(source)
    if nargin<2 || isempty(index)
        source = fullfile(pwd,'unittest',[ 'headertest_' strrep(headername,'/','_') '.cpp' ]);
    else
        source = fullfile(pwd,'unittest',[ 'headertest_' sprintf('%.3d',index) '_' strrep(headername,'/','_') '.cpp' ]);
    end
end

f = fopen(source,'wt');
if f<0
    error('mwood:headertest:fopen','Failed to open: %s',source);
end
closefile = onCleanup(@() fclose(f));

fprintf(f,'// Copyright 2016 The MathWorks, Inc.\n');
fprintf(f,'\n');
fprintf(f,'#include "version.h"\n');
fprintf(f,'\n');
fprintf(f,'#include "%s"\n',relheader);
fprintf(f,'\n');
%fprintf(f,'#include "test_manager.h"\n');
%fprintf(f,'\n');
fprintf(f,'\n');

% 
% fprintf(f,'#ifdef _MW_UTIL_H_\n');
% fprintf(f,'#error %s must not include util.h\n',relheader);
% fprintf(f,'#endif\n\n');
% 
% fprintf(f,'#ifdef __UDD_UDD_H__\n');
% fprintf(f,'#error %s must not include udd.h\n',relheader);
% fprintf(f,'#endif\n\n');
% 
% fprintf(f,'#ifdef m_interpreter_h__\n');
% fprintf(f,'#error %s must not include m_interpreter.h\n',relheader);
% fprintf(f,'#endif\n\n');
% 
% fprintf(f,'#ifdef export_matrix_h\n');
% fprintf(f,'#error %s must not include matrix.h\n',relheader);
% fprintf(f,'#endif\n\n');
% 
% fprintf(f,'#ifdef mcos_h\n');
% fprintf(f,'#error %s must not include mcos.h\n',relheader);
% fprintf(f,'#endif\n\n');
% 
% fprintf(f,'#ifdef _ALLOW_SERVICES_DEPRECATED_HPP_\n');
% fprintf(f,'#error %s must not include services.h\n',relheader);
% fprintf(f,'#endif\n\n');


v = genvarname(headername);

fprintf(f,'\n');
fprintf(f,'int testHeader_%s() {\n',v);
fprintf(f,'   return 99;\n');
fprintf(f,'}\n');
fprintf(f,'\n');

delete(closefile);

fprintf('Created %s\n',source);

end