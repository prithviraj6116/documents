function make_compile_standalone_sbmininclude(header)
% Uses the sbmininclude tool to add necessary #includes to a header
%
% make_compile_standalone_sbmininclude(header)
%
% Runs sbmininclude on a header's corresponding source file.  This modifies
% the header too.  Postprocess to ensure that no existing inclusions are
% removed from the header.


[d,n] = fileparts(header);
cpp = fullfile(d,[n '.cpp']);
if ~exist(cpp,'file')
    error('mwood:tools:nocpp','Can''t find corresponding CPP file');
end

system(['sbmininclude ' cpp]);

% Get the list of headers that sbmininclude put in the header.
h = included_headers_in_file(header);

% Revert changes to BOTH files.
system(['p4 revert ' cpp]);
system(['p4 revert ' header]);

% Re-insert all the headers that sbmininclude added to the header.  Don't
% remove any existing ones, thus ensuring that any other files which
% include this header are not affected.
for i=1:numel(h)
    insert_header(header,h{i});
end

sbcc(header);