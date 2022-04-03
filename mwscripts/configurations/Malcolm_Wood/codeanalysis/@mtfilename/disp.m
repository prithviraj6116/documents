function disp(obj)
%MTFILENAME/DISP

s = size(obj);
disp(sprintf('mtfilename: (%dx%d)\n',s(1),s(2)));
if any(s>0)
    fn = {obj.absname};
    ef = cellfun('isempty',fn);
    if any(ef)
        % Empty absname could be a truly empty object, or a command we can't find
        commands = {obj(ef).command};
        ec = cellfun('isempty',commands);
        % These ones are truly empty: no command specified
        commands(ec) = {'(empty)'};
        % These ones are commands we can't find
        commands(~ec) = strcat(commands(~ec),{'  (not found)'});
        fn(ef) = commands;
    end
    d = logical([obj.isdir]);
    desc = cell(size(fn));
    % These are directories
    desc(d) = {'   (directory)'};
    % These are files that we could find
    desc(~d & ~ef) = {'   (file)'};
    h = strcat({'   '}, fn, desc);
    disp(sprintf('%s\n',h{:}));
else
    disp('');
end

