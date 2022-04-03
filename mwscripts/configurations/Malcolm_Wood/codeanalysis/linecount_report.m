function outfile = linecount_report(headers,preprocess,compile)
% linecount_report - preprocesses and/or compiles files in the current
%                    module and reports on line counts
%
% linecount_report(headers,preprocess,compile)
%
% Generates ./preprocessor_counts_hpp.csv or ./preprocessor_counts_cpp.csv

if nargin<3
    compile = false;
    if nargin<2
        preprocess = true;
        if nargin<1
            headers = false;
        end
    end
end

if headers
    ext = '.hpp';
    outfile = 'preprocessor_counts_hpp.csv';
else
    ext = '.cpp';
    outfile = 'preprocessor_counts_cpp.csv';
end

files = find_files_by_type(ext);
f = fopen(outfile,'w');
if f<=0
    error('mwood:tools:line_count_report','Cannot open file for writing: %s',outfile);
end
fclose(f);

i_print(outfile,'Filename,LineCount,PreprocessedCount,Compiles\n');

h = waitbar(0,'Analyzing files...');
c = onCleanup(@() delete(h));
n = numel(files);
max_preproc = 0;
total_source = 0;
total_preproc = 0;
total_test = 0;
total_test_preproc = 0;
for i=1:n
    if ishandle(h)
        waitbar(i/n,h,sprintf('Analyzing files... (%d of %d)',i,n));
    end
    % Skip files in "unittest" and "pkgtest" folders.
    is_test = false;
    if ~isempty(regexp(files{i},'\/unittest\/','once'))
        is_test = true;
    elseif ~isempty(regexp(files{i},'\/pkgtest\/','once'))
        is_test = true;
    end
    if preprocess
        try
            [count,orig] = preprocessed_linecount(files{i});
            if is_test
                total_test = total_test + orig;
                total_test_preproc = total_test_preproc + count;
                max_preproc = max(max_preproc,count);
            else
                total_source = total_source + orig;
                total_preproc = total_preproc + count;
                max_preproc = max(max_preproc,count);
            end
            count = num2str(count);
            orig = num2str(orig);
        catch E
            count = 'Can''t preprocess';
            disp(E.message);
            try
                orig = linecount(files{i});
                total_source = total_source + orig;
                orig = num2str(orig);
            catch F
                disp(F.message)
                orig = 'Can''t count';
            end
        end
    else
        orig = linecount(files{i});
        total_source = total_source + orig;
        orig = num2str(orig);
        count = '0';
    end
    if compile
        try
            sbcc(files{i});
            compiles = true;
        catch
            compiles = false;
        end
    else
        compiles = true; % unless we're analysing a module that doesn't build
    end
    i_print(outfile,'%s,%s,%s,%d\n',files{i},orig,count,compiles);
end
i_print(outfile,'Total source lines: %d\n',total_source);
i_print(outfile,'Total preprocessed lines: %d\n',total_preproc);
i_print(outfile,'Total test lines: %d\n',total_test);
i_print(outfile,'Total preprocessed test lines: %d\n',total_test_preproc);
i_print(outfile,'Maximum preprocessed lines: %d\n',max_preproc);
end

function i_print(outfile,fmt,varargin)
    f = fopen(outfile,'a');
    fprintf(f,fmt,varargin{:});
    fclose(f);
    fprintf(fmt,varargin{:});
end


