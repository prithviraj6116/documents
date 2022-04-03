function compare_linecount_reports(other_sandbox_root)

r = sbroot;
d = pwd;
if ~strncmp(d,[r '/'],numel(r)+1)
    error('mwood:tools:linecount','pwd is not inside sbroot')
end
rel = d(numel(r)+1:end);

f1 = fullfile(d,'preprocessor_counts_cpp.csv');
if ~exist(f1,'file')
    error('mwood:tools:linecount','File not found: %s',f1);
end

f2 = fullfile(other_sandbox_root,rel,'preprocessor_counts_cpp.csv');
if ~exist(f2,'file')
    error('mwood:tools:linecount','File not found: %s',f2);
end

t1 = readtextfile(mtfilename(f1));
t2 = readtextfile(mtfilename(f2));

for i=2:numel(t1)
    m1 = mt_tokenize(t1{i},',');
    m2 = mt_tokenize(t2{i},',');
    if numel(m1) ~= 4
        continue;
    end
    if numel(m2) ~= 4
        continue;
    end
    if ~strcmp(m1{1},m2{1})
        error('mwood:tools:linecount','File names don''t match at line %d',i);
    end
    lines1 = str2double(m1{3});
    lines2 = str2double(m2{3});
    if abs(lines1-lines2)/lines1 > 0.001
        fprintf('Difference: %s:   %d - %d\n',m1{1},lines1,lines2);
    end
end

end