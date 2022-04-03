function generate_header_trees(force)
% generate_header_trees - Generates _headertree files for all C++ files

if nargin<1
    force = false;
end

fprintf('Generate header trees: %s\n',pwd);
files = find_files_by_type('.cpp');
fprintf('Generating header tree for:\n');
h = waitbar(0,'Generating header trees...');
c = onCleanup(@() delete(h));
n = numel(files);
for i=1:n
    waitbar(i/n,h,sprintf('Generating header trees... (%d of %d)',i,n));
    if ~force
        if exist([files{i} '_headertree'],'file')
            continue;
        end
    end
    fprintf('   %s\n',files{i});
    try
        headertree(files{i});
    catch E
        disp(E.message);
    end
end
fprintf('Finished\n');