function [fcnIds, scriptIds] = getIncludedFunctions(report, hideInternal)

%   Copyright 2016-2019 The MathWorks, Inc.

    if ~isfield(report, 'inference') || isempty(report.inference)
        fcnIds = [];
        scriptIds = [];
        return;
    end

    allFcns = report.inference.Functions;
    scripts = report.inference.Scripts;
    
    scriptCount = numel(scripts);            
    allFcnScriptIds = [allFcns.ScriptID];   
    
    mask = allFcnScriptIds > 0 & allFcnScriptIds <= scriptCount;

    % Currently, this hides all the SFX internal functions
    if numel(allFcns) > 1 && nargin > 1 && hideInternal
        for i =1:length(mask)
            if allFcnScriptIds(i) > 0 && endsWith(scripts(allFcnScriptIds(i)).ScriptPath, '.sfx') 
                if ~isequal(allFcns(i).FunctionName, allFcns(i).ClassName) && ~isequal(allFcns(i).FunctionName, 'step')
                    %hides sfx internal function (DONE)
                    %shows user visible functions (DONE): constructor,step
                    %show user visible functions (@TODO): ML functions, event functions, graphical functions
                    mask(i) = false;
                end
            end
        end
    end
    if numel(allFcns) > 1 && nargin > 1 && hideInternal       
        mask(mask) = [scripts(allFcnScriptIds(mask)).IsUserVisible];
        for i = find(~mask)
            fcn = allFcns(i);
            if ~isempty(fcn.Messages) && hasErrors(fcn.Messages) && ~endsWith(scripts(allFcnScriptIds(i)).ScriptPath, '.sfx')
                mask(i) = true;
            elseif fcn.IsExtrinsic || fcn.IsAutoExtrinsic
                mask(i) = true;
            end
        end
    end
    
    if isprop(report.inference, 'RootFunctionIDs') && ~isempty(report.inference.RootFunctionIDs)
        maskCount = nnz(mask);
        if ~hideInternal || maskCount == 0
            mask(report.inference.RootFunctionIDs) = true;
            if maskCount == 0
                % Artificially include all functions in the scripts
                % containing the root functions. (g1764707)
                rootScriptIds = [allFcns(report.inference.RootFunctionIDs).ScriptID];
                rootScriptIds = unique(rootScriptIds(rootScriptIds > 0));
                mask(ismember(allFcnScriptIds, rootScriptIds)) = true;
            end
        end
    end
    
    fcnIds = find(mask);
    fcns = allFcns(mask);    
    scriptIds = unique([fcns.ScriptID]);
    scriptIds = scriptIds(scriptIds > 0);
end

function yes = hasErrors(msgs)
    yes = false;
    for i = 1:numel(msgs)
       if any(strcmp({'Fatal', 'Error'}, msgs(i).MsgTypeName))
           yes = true;
           break;
       end
    end
end

% LocalWords:  SFX sfx
