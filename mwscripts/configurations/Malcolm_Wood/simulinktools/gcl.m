function [line_handle,msg] = gcl
%GCL Returns the handle to the "current" line
%
% [line_handle,msg] = gcl;
%
% Only lines which are attached to outports can be "current".
% If no line is "current", the handle is -1 and a
% message is returned.
%

msg = '';
sys = gcs;
if isempty(sys)
    line_handle = -1;
    msg = 'No current system.';
    return;
end

port = get_param(sys,'CurrentOutputPort');
if isempty(port)
    line_handle = -1;
    msg = 'No output port selected.  Select a line which is connected to an output port.';
    return;
end
line_handle = get_param(port,'Line');
if isempty(line_handle)
    line_handle = -1;
    % Unlikely
    msg = 'No line selected.  Select a line which is connected to an output port.';
end

