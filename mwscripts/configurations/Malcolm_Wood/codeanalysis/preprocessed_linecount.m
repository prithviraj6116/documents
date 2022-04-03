function [count,orig] = preprocessed_linecount(filename,force)
% Returns the number of lines in the preprocessor output for the
% specified source file.
%
% The source file must be of a type that can be processed by "sbcc".

src = mtfilename(filename);
restore = mt_cd(find_module_folder(getabs(src))); %#ok<NASGU>
filename = relativepath(src,pwd);

needs_preproc = true;
if nargin<2 || ~force
    [d,n,e] = fileparts(filename);
    ifile = mtfilename(fullfile(d,[n '_RELEASE_SUPER-STRICT' e '_i']));
    if exist(ifile,'file') && newerthan(ifile,filename) && linecount(getabs(ifile))~=0
        needs_preproc = false;
    end
end
if needs_preproc
    ifile = mtfilename(preprocess(filename));
end
count = linecount(getabs(ifile));
orig = linecount(filename);

end
