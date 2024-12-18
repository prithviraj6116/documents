function generate_header_trees_parallel(force)
% generate_header_trees - Generates _headertree files for all C++ files
%
% Run matlabpool('local',6) first

if nargin<1
    force = false;
end

fprintf('Generate header trees: %s\n',pwd);
files = find_files_by_type('.cpp');
fprintf('Generating header tree for:\n');

dir = fileparts(mfilename('fullpath'));
javaaddpath(dir);

n = numel(files);
ppm = ParforProgMon('Generating header trees', n);
c = onCleanup(@() delete(ppm));

pctRunOnAll addpath /public/Malcolm_Wood/codeanalysis
pctRunOnAll javaaddpath /public/Malcolm_Wood/codeanalysis

parfor i=1:n
    ppm.increment; %#ok<PFBNS>
    fprintf('Generating tree for %s (pid=%d)',files{i},feature('getpid'));
    if ~force
        if exist([files{i} '_headertree'],'file')
            fprintf('  (already exists)\n');
            continue;
        end
    end
    fprintf(' ...\n');
    try
        headertree(files{i});
    catch E
        disp(E.message);
    end
end
fprintf('Finished\n');
