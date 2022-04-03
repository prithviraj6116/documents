function scan_resave_logs

component = 'simulink_demos_industrial';
cluster = 'Bslengine_integ';
job = '151714';

platforms = {'glnxa64','maci64','win32','win64'};
t = cell(1,4);
has_warnings = false;
for i=1:4
    [log,w] = i_extract(cluster,job,platforms{i},component);
    t{i} = sprintf('%s:\n\n%s\n',platforms{i},log);
    has_warnings = has_warnings || w;
    if w
        fprintf('Warnings found on %s\n',platforms{i});
    end
end
f = [tempname 'txt'];
i_writetextfile(f,t);
edit(f);
delete(f);
end

function [t,w] = i_extract(cluster,job,platform,component)

log = i_find(cluster,job,platform,component);
t = i_readtextfile(log);
s = regexp(t,'MODELS_TO_SAVE','once');
if ~isempty(s)
    s = regexp(t(1:s),'build entering');
    s = s(end);
    if ~isempty(s)
        e = regexp(t(s:end),'build exiting','once');
        if ~isempty(e)
            t = t(s:s+e+42); % allow space for the date stamp
            w = i_has_warnings(t);
            return;
        end
    end
end
t = '<not found>';

end

% Returns the full path of the log file containing the first build-run of
% the component.
function log = i_find(cluster,job,platform,component)
for run = 1:10
    tag = ['build.' platform '.' job '.r' sprintf('%.3d',run)]; % e.g. build.win32.151714.r001
    log = ['/mathworks/devel/bat/' cluster '/logs/' job '/' tag '/' tag '.' component '.log'];
    if ~isempty(dir(log))
        return;
    end
end
error('No log found');
end

% Returns true if warnings are found in the resave log.
function w = i_has_warnings(t)
start_marker = 'Running slmodels_resave';
end_marker = 'slmodels_resave completed';
s = regexp(t,start_marker,'once');
if ~isempty(s)
    e = regexp(t(s:end),end_marker,'once');
    if (e)
        t = t(s:s+e);
        w = ~isempty(regexp(t,'Warning:','once'));
    else
        % End not found.  Suggests a problem.
        w = true;
    end
else
    % Didn't resave.  No problem.
    w = false;
end

end

% Writes a string or cell array of strings to a text file
function i_writetextfile(f,c)

assert(ischar(f),'File name must be a string');

hf = fopen(f,'wt');
if hf<0
    error('mwood:tools:fopen','Failed to open %s for writing',f);
end
closefile = onCleanup(@() fclose(hf));

if ischar(c)
    fprintf(hf,'%s',c);
elseif iscell(c)
    assert(all(cellfun(@ischar,c)),'All cells must contain strings');        
    fprintf(hf,'%s\n',c{:});
end
end

% Returns the contents of a text file
function t = i_readtextfile(f)

assert(ischar(f),'File name must be a string');

hf = fopen(f,'rt');
if hf<0
    error('mwood:tools:fopen','Failed to open %s for reading',f);
end
closefile = onCleanup(@() fclose(hf));

t = fread(hf,'*char')';
assert(feof(hf)==1,'Failed to read to the end of the file');
end