function files = find_files_by_type(ext)
% find_files_by_type - Returns files with a specified extension in this
%   folder and its subfolders.
%
% files = find_files_by_type(ext)
%
% ext should include the leading dot.

[status,files] = system(['find . -name \*' ext]);
if status~=0
    error('mwood:tools:find','%s',files);
end
files = mt_tokenize(files,char(10));
files = sort(files);
