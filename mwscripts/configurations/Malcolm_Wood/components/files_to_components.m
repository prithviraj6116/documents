function c = files_to_components(f,silent)
% files_to_components - Identifies the components that own files
%
% c = files_to_components(f)
%
% Uses "sbfi", which must be on the system path.

if nargin<2
    silent = false;
end

if ischar(f)
    c = files_to_components({f},silent);
    c = c{1};
    return;
end

c = f;

for i=1:numel(f)
    if ~silent
        fprintf('%d: %s',i,f{i});
    end
    cmd = ['sbfi matlab/' f{i}];
    [~,out] = system(cmd);
    m = regexp(out,'Component: (?<comp>[\/\w]*)','names');
    if ~isempty(m)
        c{i} = m.comp;
    else
        c{i} = out;
    end
    if ~silent
        fprintf(' %s\n',c{i});
    end
end