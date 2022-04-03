function window_title
% Sets the window title of the MATLAB Desktop to indicate the cluster and
% job number.

if ~usejava('desktop')
    fprintf('No desktop\n');
    return;
end

r = matlabroot;
r = fileparts(r);
[r,d,e] = fileparts(r);
d = [d e];
if strcmp(d,'perfect')
    [~,d] = fileparts(r);
    d = [d ' perfect'];
elseif strcmp(d,'build')
    [r,d] = fileparts(r);
    if strcmp(d,'current')
        [~,d] = fileparts(r);
    end
end
desktop = com.mathworks.mlservices.MatlabDesktopServices.getDesktop.getMainFrame;
count = 0;
while isempty(desktop)
    pause(0.1);
    desktop = com.mathworks.mlservices.MatlabDesktopServices.getDesktop.getMainFrame;
    count = count + 1;
    if count>20
        warning('Can''t get desktop frame!');
        return;
    end
end
pause(0.1);
% Set the frame title.  If called at startup, it's quite likely that this
% will get overwritten by something else, so also print a hyperlink
% allowing the user to re-set it.
desktop.setTitle(['MATLAB ' d]);
cmd = ['com.mathworks.mlservices.MatlabDesktopServices.getDesktop.getMainFrame.setTitle(''MATLAB ' d ''')'];
href = ['<a href="matlab:' cmd '">Set Window title to "MATLAB ' d '"</a>'];
fprintf('%s\n',href);

end