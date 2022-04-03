function f = mt_fullfile(varargin)

persistent got_slfullfile;
if isempty(got_slfullfile)
    got_slfullfile = ~isempty(which('slfullfile'));
end

if got_slfullfile
    f = slfullfile(varargin{:});
else
    f = fullfile(varargin{:});
end