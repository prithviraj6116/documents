function [linecounts,filecounts] = headerplot(filename)
% headerplot - Finds the lengths of all the files included, directly and
%    indirectly, by the specified file.  Classifies the results and
%    plots a bar chart showing the contributions by module.

suffix = '_headerlist_unclassified';
treefile = mtfilename([filename suffix]);
if exist(treefile,'file') && newerthan(treefile,filename)
   % Header list already exists and is recent enough
   [linecounts,filecounts] = i_headerplot(treefile); 
else
    headertree(filename);
    [linecounts,filecounts] = i_headerplot(treefile);
end

%if nargout<2
%    filecounts %#ok<NOPRT>
%end

end

%-----------------------------------
function [linecounts,filecounts] = i_headerplot(treefile)

headers = readtextfile(treefile);
linecounts = struct;
filecounts = struct;
for i=1:numel(headers)
    filename = headers{i};
    if isempty(filename)
        continue;
    end
    [type,classified,canonical] = classifyheader(filename);
    if strcmp(type,'3')
        match = regexp(classified,'\$3p\/(?<module>[^\/]*)\/','names');
        i_add(match.module,canonical);
    elseif strcmp(type,'s')
        i_add('system',canonical);
    elseif strncmp(classified,'$exp/',5)
        match = regexp(classified,'\$exp\/(?<module>[^\/]*)\/','names');
        i_add(match.module,canonical);
    elseif strncmp(classified,'$fl/',5)
        i_add('fl',canonical);
    elseif strncmp(classified,'$slinc/',5)
        i_add('slinc',canonical);
    elseif strncmp(classified,'$inc/',5)
        [~,mod] = fileparts(classified);
        i_add(mod,canonical);
        %i_add('inc',canonical);
    elseif strncmp(classified,'$pwd/',5)
        i_add('pwd',canonical);
    elseif strncmp(classified,'$res/',5)
        match = regexp(classified,'\$res\/(?<module>[^\/]*)\/','names');
        i_add(['res_' match.module],canonical);
        %i_add('res',canonical)
    elseif strncmp(classified,'$derived/',9)
        %i_add('derived',canonical)
        match = regexp(classified,'\$derived\/glnxa64\/src\/include\/(?<module>[^\/]*)\/','names');
        if isempty(match)
            match = regexp(classified,'\$derived\/(?<module>[^\/]*)\/','names');
        end
        i_add(match.module,canonical);
    else
        i_add('unclassified',filename);
        fprintf('Unclassified: %s (%s)\n',classified,type);
    end
end
i_plot(linecounts);
linecounts = i_sort_fields(linecounts);
filecounts = i_sort_fields(filecounts);


    %-------------------------------------
    function i_add(modname,fname)
        modname = matlab.lang.makeValidName(modname);
        if ~isfield(linecounts,modname)
            linecounts.(modname) = 0;
        end
        linecounts.(modname) = linecounts.(modname) + linecount_database(fname);
        if ~isfield(filecounts,modname)
            filecounts.(modname) = 0;
        end
        filecounts.(modname) = filecounts.(modname) + 1;
    end
end

%------------------------------------
function i_plot(mods)
    figure;
    nums = cell2mat(struct2cell(mods));
    mods = fieldnames(mods);
    [nums,order] = sort(nums,1,'descend');
    mods = mods(order);
    max = 30;
    if numel(nums)>max
        nums = nums(1:max);
        mods = mods(1:max);
    end
    bar(nums');
    
    g = gca;
    g.XTick = 1:numel(mods);
    g.XTickLabel = mods;
    g.TickLabelInterpreter = 'none';
    g.XTickLabelRotation = 45;
    
    fprintf('Sorted top %d:\n',max);
    for i=1:numel(nums)
        fprintf('%30s: %d\n',mods{i},nums(i));
    end
end

%------------------------------------
function newmods = i_sort_fields(mods)
    f = sort(fieldnames(mods));
    newmods = struct;
    for i=1:numel(f)
        newmods.(f{i}) = mods.(f{i});
    end
end

