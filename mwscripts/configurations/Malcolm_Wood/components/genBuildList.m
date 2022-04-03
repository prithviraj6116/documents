% The components we want to work on
reqcomps = readtextfile(mtfilename('/public/Malcolm_Wood/components/Bslx_required_comps.txt'));
% The tests we want to run
testcomps = readtextfile(mtfilename('/public/Malcolm_Wood/components/Bslx_required_tests.txt'));

allcomps = {};
reqcurrent = reqcomps;
% In theory we need to call downstreamComponentsTo on each pair of
% components, but we can skip any which are already in the allcomps set.
for i=1:numel(testcomps)
    if ismember(testcomps{i},allcomps)
        continue;
    end
    %reqcurrent = reqcurrent(~ismember(reqcurrent,allcomps));
    for k=1:numel(reqcurrent)
        try
            ct = c.downstreamComponentsTo(reqcurrent{k},testcomps{i});
            allcomps = unique([allcomps(:);ct(:);reqcurrent(k);testcomps(i)]);
            fprintf('Added %s->%s (%d, %d)\n',testcomps{i},reqcurrent{k},numel(ct),numel(allcomps));
        end
    end
end
fprintf('Found %d components in set\n',numel(allcomps));

ignore_list = readtextfile(mtfilename('/public/Malcolm_Wood/components/Bslx_ignore_list.txt'));
n = numel(ignore_list);
ignore_list = c.matchingComponentNames(ignore_list);
fprintf('Found %d entries (matching %d components) in ignore list\n',...
                n,numel(ignore_list));
            
allcomps = setdiff(allcomps,ignore_list);
allcomps = unique([allcomps(:);reqcomps(:);testcomps(:)]);
fprintf('Fount %d components to build\n',numel(allcomps));