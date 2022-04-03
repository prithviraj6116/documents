function common_startup

d = fileparts(mfilename('fullpath'));
addpath(d);
addpath(fullfile(fileparts(d),'slxtools'));
addpath(fullfile(fileparts(d),'simulinktools'));
addpath(fullfile(fileparts(d),'codeanalysis'));
addpath(fullfile(fileparts(d),'components'));
addpath(fullfile(fileparts(d),'modules'));
addpath(fullfile(fileparts(d),'matlabtools'));
addpath /md/mwood/helpers/mwpresubmit
disp('Path modifications done');
drawnow;
window_title;
