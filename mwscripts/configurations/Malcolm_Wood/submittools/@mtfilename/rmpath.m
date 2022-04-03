function rmpath(obj)
%MTFILENAME/RMPATH Removes the specified directory from the MATLAB path
%
% rmpath(obj)
%
% The specified object must represent a directory

for i=1:length(obj)
    if ~obj(i).isdir
        error(sprintf('The specified path is not a directory: %s',obj(i).absname));
    end
    rmpath(obj(i).absname);
end

