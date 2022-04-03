function postreview(submit_file,reviewnum)
% postreview - Submits a review to the Review Board server
%
% postreview(submitfile) % new review
% postreview(submitfile,reviewnum) % update existing review
%
% submitfile must be a submit file in the standard format
% review is optional and can be a number or a string
%
% Diffs are generated using "mdiff" in the current sandbox.
%
% e.g.
% postreview submit.txt           % submit a new review
% postreview submit.txt 123       % update review 123
% postreview('submit.txt','123')  % update review 123

submit_file = mtfilename(submit_file);
[files,reviewers,gecks,desc,summary] = parse_submitfile(submit_file);

subdir = parentdir(submit_file);
isroot = strcmp(getabs(subdir),sbroot(submit_file));

% We need to be within the "matlab" folder for post-review to be able to find
% the CVS information it needs.  Strip "matlab/" from each file name if
% we're at the sandbox root.
for i=1:numel(files)
    if isroot
        if strncmp(files{i},'matlab/',7)
            files{i} = files{i}(8:end);
        else
            warning('mwood:tools:postreview','File name not at root of sandbox: %s',files{i});
        end
    end
    if isroot
        absfile = fullfile(subdir,'matlab',files{i});
    else
        absfile = fullfile(subdir,files{i});
    end
    if ~exist(absfile,'file');
        error('mwood:tools:postreview','File not found: %s',files{i});
    end
end
% Generate the command
cmd = sprintf(' %s',files{:});
if nargin>1 && ~isempty(reviewnum)
    if ischar(reviewnum)
        reviewnum = sprintf(' -r %s',reviewnum);
    else
        reviewnum = sprintf(' -r %d',reviewnum);
    end
else
    reviewnum = '';
end
if ~isempty(reviewers)
    reviewers = [' --target-people ' reviewers];
end
if ~isempty(gecks)
    gecks = [' --bugs-closed ' gecks];
end
descfile = mtfilename(tempname);
if ~isempty(desc)
    writetextfile(descfile,desc);
    desc = [' --description-file=' getabs(descfile)];
end
if ~isempty(summary)
    summary = [' --summary="' summary '"'];
end
cmd = ['post-review ' reviewnum gecks reviewers desc summary cmd];
if isroot
    % Change into the "matlab" folder temporarily to execute the command.
    d = cd('matlab');
    restoredir = onCleanup(@() cd(d));
else
    restoredir = [];
end
disp(cmd);
[a,b] = system(cmd);
disp(a);
disp(b);
delete(restoredir);
if exist(descfile,'file')
    delete(descfile);
end
% Open it in the browser
%review_url = regexp(b,'(?<url>http.*)$','names');
%web(review_url.url);
