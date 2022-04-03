function [pmap,omap] = read_linecount_report(filename)

t = mt_readtextfile(filename);
t(1) = [];
omap = containers.Map;
pmap = containers.Map;
for i=1:numel(t)
    q = strsplit(t{i},',');
    if numel(q)>=3
        f = q{1};
        if f(1)=='.' && f(2)=='/'
            f(1:2) = [];
        end
        omap(f) = str2double(q{2});
        pmap(f) = str2double(q{3});
    end
end

end