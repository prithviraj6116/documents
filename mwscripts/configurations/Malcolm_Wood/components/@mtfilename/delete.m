function delete(obj,force)
%MTFILENAME/DELETE Deletes the specified file
%
% delete(obj)
% delete(obj,force)
%
% If "force" is specified and non-zero, the file will be made
% writable before being deleted.
% This method works for multiple files.

if nargin>1 & force
    for i=1:numel(obj)
        dos(['attrib -R "' getabs(obj(i)) '"']);
    end
end

for i=1:length(obj)
    f = getabs(obj(i));
    delete(f);
end


