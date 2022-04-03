function addpath(obj)
%MTFILENAME/ADDPATH Adds the specified directory to the MATLAB path
%
% addpath(obj)
%
% The specified object must represent a directory

for i=1:length(obj)
    if ~obj(i).isdir
        error(sprintf('The specified path is not a directory: %s',obj(i).absname));
    end
    addpath(obj(i).absname);
end

