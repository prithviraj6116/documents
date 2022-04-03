function gvim(filename)
% Opens the specified file in GVIM.
% If no file is specified, the file currently open in the MATLAB Editor is
% used.

if nargin<1 || isempty(filename)
    filename = editordoc;
end

system(['gvim ' filename]);

end