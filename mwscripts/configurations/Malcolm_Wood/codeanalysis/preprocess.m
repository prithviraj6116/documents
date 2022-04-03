function outputfile = preprocess(filename)
% preprocess - Runs the C++ preprocessor on the specified file
%
% outputfile = preprocess(filename)
%
% The input can be a file in any format supported by "sbcc".

[status,out] = system(['sbcc -rc -E ' filename]);
if status~=0
    error('Malcolm:preproc:sbcc','%s',out);
end
% Find the output filename.  It appears after "preprocess output to",
% ends in "_i", and doesn't include whitespace..
outputfile = regexp(out,'preprocessor output to (?<name>[^\s]*_i\>)','names');
if isempty(outputfile)
    error('Malcolm:preproc:sbcc','%s',out);    
end
relpath = outputfile.name;
% Try to resolve the output file.  It may have been returned relative to
% a different folder.
outputfile = fullfile(pwd,relpath);
if ~exist(outputfile,'file')
    outputfile = which(relpath);
    if ~exist(outputfile,'file')
        error('Malcolm:preproc:output','Output file not found: %s',relpath);
    end
end
