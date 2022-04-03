function output = decodestack(s,is_file)
% decodestack - Decodes and returns the supplied C++ stack trace

if nargin<2 || ~is_file
    % Save the stack in a temporary file
    tmpfile = [tempname '.txt'];
    writetextfile(mtfilename(tmpfile),s);
    deletefile = onCleanup(@() delete(tmpfile));
else
    % Treat s as a filename
    tmpfile = s;
end

decoder = fullfile(matlabroot,'bin','stack_decoder.pl');
if ~exist(decoder,'file')
    decoder = fullfile(matlabroot,'tools','share','stack_decoder.pl');
    if ~exist(decoder,'file')
        error('mwood:tools:decodestack','Can''t find stack_decoder.pl')
    end
end

cmd = ['mw -using ' fileparts(matlabroot) ' perl ' decoder ' --in=' tmpfile];
[success,output] = system(cmd);
if success~=0
    disp(s);
    error('mwood:tools:decodestack',...
        'Failed to decode stack trace: %s\n',output);
end
