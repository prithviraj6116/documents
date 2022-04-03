function out = last_compiler_error(in)

persistent sMessage;

if nargin
    sMessage = in;
    mt_writetextfile('compiler_output.txt',in);
end

if nargout || ~nargin
    out = sMessage;
end

end
