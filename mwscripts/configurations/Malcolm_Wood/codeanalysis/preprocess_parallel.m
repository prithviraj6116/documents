function preprocess_parallel(force)
% preprocess_parallel - Preprocess all C++ files in the current folder
%
% Run parpool('local',8) first

files = find_files_by_type('.cpp');

if nargin<1
    force = false;
end

dir = fileparts(mfilename('fullpath'));
javaaddpath(dir);

n = numel(files);
ppm = ParforProgMon('Preprocessing', n);
c = onCleanup(@() delete(ppm));

pctRunOnAll addpath /public/Malcolm_Wood/codeanalysis
pctRunOnAll javaaddpath /public/Malcolm_Wood/codeanalysis

total_preprocessed = 0;
total_orig = 0;

parfor i=1:n
    ppm.increment;
    try
        fprintf('Preprocessing %s (pid=%d)',files{i},feature('getpid'));
        [count,orig] = preprocessed_linecount(files{i},force);
        fprintf(' (count=%d) ...\n',count);
        total_preprocessed = total_preprocessed + count;
        total_orig = total_orig + orig;
    catch E
        fprintf(' (failed)\n');
        disp(E.message);
    end
end

fprintf('Total source: %d\n',total_orig);
fprintf('Total preprocessed: %d\n',total_preprocessed);
end
