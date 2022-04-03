function checkBslxCTB
% Checks the Bslx CTB list for required components

ctb_bslx = getClusterCTB('Bslx');

ctb_bslengine = getClusterCTB('Bdacore_integ');
extra = setdiff(ctb_bslx,ctb_bslengine);
if ~isempty(extra)
    fprintf('Identified components that are missing from Bslengine_integ\n');
    fprintf('   %s\n',extra{:});
end

% Bslx needs to build all clients of the resave harness
i_check('slmodels_resave_and_build.mk',ctb_bslx);

% Bslx needs to build all clients of the slexportprevios makefile
i_check('slexportprevious.mk',ctb_bslx);

% Bslx needs to build all clients of the sltemplate make harness
i_check('sltemplate_make_harness.mk',ctb_bslx);

% Bslx needs to build all components containing featured example providers
% and their tests.
i_check('FeaturedExampleProvider',ctb_bslx);
i_check('FeaturedExampleProviderTest',ctb_bslx);

i_sbsmartbuild(ctb_bslx);

end

function i_check(search_term,ctb_bslx)
    fprintf('Checking %s\n',search_term);
    % Find files in Bslengine_integ which contain the search term
    files = codesearch(search_term,'Bslengine_integ',true);
    comps = files_to_components(files,true); % silent
    missing = setdiff(comps,ctb_bslx);
    missing(strcmp(missing,'matlab_local')) = []; % path cache
    if ~isempty(missing)
        fprintf('Identified missing components for search term "%s"\n',search_term);
        fprintf('   %s\n',missing{:});
    end
end

function i_sbsmartbuild(ctb_bslx)
  fprintf('Checking sbsmartbuild\n');
  f = fopen('submit.txt','wt');
  fprintf(f,'matlab/src/simstruct/export/include/simstruct/simstruc.h\n');
  fprintf(f,'matlab/src/sl_services/export/include/sl_services/slsv_diagnostic.hpp\n');
  fprintf(f,'matlab/src/smaht/export/include/smaht/layout/LayoutRect.hpp\n');
  fprintf(f,'matlab/src/glee_util/export/include/glee_util/types/StringType.hpp\n');
  fclose(f);
  system('sbsmartbuild -F submit.txt -mode module -no-build');
  t = mt_readtextfile('submit.txt.sbsmartbuild.mk');
  i1 = find(mt_regexp(t,'# CppModDirs'));
  i2 = find(mt_regexp(t,'# EndCppModDirs'));
  lines = t(i1+1:i2-1);
  for i=1:numel(lines)
      lines{i}(1) = []; % strip leading '#'
      lines{i} = strtrim(lines{i});
  end
  comps = unique(files_to_components(lines,true));
  missing = setdiff(comps,ctb_bslx);
  if ~isempty(missing)
      fprintf('Identified missing components for sbsmartbuild\n');
      fprintf('   %s\n',missing{:});
  end
  

end
