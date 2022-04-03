function saveSuccess = SaveAs(modelHandle, filePath, explicitRename, checkFolderPermission)
%

%   Copyright 2016-2019 The MathWorks, Inc.

    saveSuccess = false;
    if ~exist('explicitRename', 'var')
        explicitRename = false;
    end
    if ~exist('checkFolderPermission', 'var')
        checkFolderPermission = true;
    end
    isNew = false;
    if exist('filePath', 'var') && ~exist(filePath, 'file')
        isNew = true;
    end
    if ~isNew && isequal(get_param(0, 'ShowEditTimeIssues'), 'off')
        errId = 'MATLAB:sfx:LintErrorOff';
        if exist('filePath', 'var') && ~isempty(filePath)
            [~, chartName, ~] = fileparts(filePath);
        else
            chartName = get_param(modelHandle, 'Name');
        end
        sldiagviewer.createStage(chartName, 'ModelName', chartName);
        sldiagviewer.reportError(getString(message(errId)), 'MessageId', errId);
        return;
    end
    renameType = 'NO_RENAME';
    % Renaming phase-1 Start
    if ~isempty(modelHandle) && (~exist('filePath', 'var') || isempty(filePath))
        %sfx model is renamed using SaveAs toolbar menu
        renameType = 'RENAME_USING_SAVEAS_UI';
        modelName = get_param(modelHandle, 'Name');
        Stateflow.App.Cdr.Runtime.InstanceIndRuntime.setModelClose(modelName,0,0);
    end
    % Renaming phase-1 End


    if nargin<2 || isempty(filePath)
        % Prompt for a file name
        [savedFileName, savedPathName] = uiputfile({'*.sfx', 'Stateflow Chart (*.sfx)'}, 'Save Stateflow Chart');
        if isequal(savedFileName, 0)
            return; % cancelled
        end
        filePath = fullfile(savedPathName, savedFileName);
    end
    [~, userFileName, ext] = fileparts(filePath);
    assert(~isempty(userFileName), 'username must not be empty');
    if ~isequal(ext, '.sfx') || contains(userFileName, '.')
        errId = 'MATLAB:sfx:InvalidFileName';
        sldiagviewer.reportError(getString(message(errId, filePath)), 'MessageId', errId);
        return; 
    end
    if ~isvarname(userFileName)
        %@todo tWorkflowTests_16/lvlTwo_InvalidFileNames
        %reaches here but coverage report shows it non-covered, why?        
        errId = 'MATLAB:sfx:InvalidFileName';
        sldiagviewer.reportError(getString(message(errId, userFileName)), 'MessageId', errId);
        return;
    end

    try
        [dirPath, userFileName, ~] = fileparts(filePath);
        mName = which(userFileName);
    catch
    end
    if checkFolderPermission
        tempSFXDirName = fullfile(dirPath,['sfxTempDir_' datestr(datetime('now'),'yymmddHHMMSS')]);
        if ~mkdir(tempSFXDirName)
            errId = 'MATLAB:sfx:PermissionsDeniedSFX';
            error(errId, getString(message(errId, filePath)), 'MessageId', errId);
        else
            rmdir(tempSFXDirName);
        end
    end

    if  (isNew || isequal(renameType,'RENAME_USING_SAVEAS_UI')) && ~isempty(mName) && ~endsWith(mName, '.sfx') && ~endsWith(mName, '.m') && ~endsWith(mName, '.p')&& ~endsWith(mName, '.mlx')&& ~endsWith(mName, '.mlapp')
        errId = 'MATLAB:sfx:SLXShadowing';
        if isNew
            modelName = get_param(modelHandle, 'Name');
            close_system(modelName, 0);            
            error(errId, getString(message(errId, mName, [userFileName '.sfx'])));
        else
            sldiagviewer.createStage(modelName, 'ModelName', modelName);
            sldiagviewer.reportError(getString(message(errId, mName, [userFileName '.sfx'])), 'MessageId', errId);
        end 
        return;
    end

    modelName = get_param(modelHandle, 'Name');
    [~, fName, ~] = fileparts(filePath);
    rt = sfroot;
    machineH = rt.find('-isa', 'Stateflow.Machine', 'Name', modelName);
    chartH = machineH.find('-isa', 'Stateflow.Chart');
    sfxFilePath = filePath;
    if ~Simulink.BlockDiagramAssociatedData.isRegistered(modelHandle, 'SFXFilePath')
        Simulink.BlockDiagramAssociatedData.register(modelHandle, 'SFXFilePath', 'string');
    end
    Simulink.BlockDiagramAssociatedData.set(modelHandle, 'SFXFilePath', filePath);


    % Renaming phase-2 Start
    oldModelName = chartH.Name;
    if ~strcmp(machineH.Path, chartH.Name)
        Stateflow.App.Cdr.Runtime.InstanceIndRuntime.setModelClose(machineH.Path,0,0);
        chartH.Name = fName;
        %sfx model is renamed on disk
        renameType = 'RENAME_ON_DISK';
    elseif ~isNew && ~strcmp(machineH.Path, fName)
        Stateflow.App.Cdr.Runtime.InstanceIndRuntime.setModelClose(machineH.Path,0,0);
        chartH.Name = fName;
    elseif ~strcmp(machineH.Path, fName)
        Stateflow.App.Cdr.Runtime.InstanceIndRuntime.setModelClose(machineH.Path,0,0);
        chartH.Name = fName;
        %sfx model is renamed using Stateflow.App.Studio.SaveAs API with destination fileName is different (could be same/different destination directory)
        renameType = 'RENAME_USING_SAVEAS_CMD';
    elseif explicitRename
        %sfx model is renamed using Stateflow.App.Studio.SaveAs API  with destination fileName same as source but destination directory is different and explicitRename is set true as third argument
        renameType = 'RENAME_USING_SAVEAS_CMD_EXPLICIT';
    end
    Stateflow.App.Cdr.Runtime.InstanceIndRuntime.setModelOpen(fName, sfxFilePath)
    % Renaming phase-2 End


    % open symbol manager windows for new sfx models
    if isNew
        editor = StateflowDI.SFDomain.getLastActiveEditorForChart(chartH.id);
        if ~isempty(editor)
            studio =editor(1).getStudio();
            Stateflow.internal.SymbolManager.ShowSymbolManagerForStudio(chartH.id, chartH.id, studio.getStudioTag());
        end
    end


    %Save Optimization Start: Skip Save if not required, throw errors if any
    confH = Stateflow.App.Cdr.CdrConfMgr.getInstance;
    %~confH.versionCheck ||
    if confH.isUnderTesting || chartH.Dirty  || ~isequal(renameType, 'NO_RENAME') || Stateflow.App.Cdr.Runtime.InstanceIndRuntime.isZoomFactorChanged(fName)
        resaveRequired = true;
        saveSuccess = true;
    else
        [r, ~] = Stateflow.App.Studio.ResaveIfSavedWithOlderVersion(sfxFilePath, modelHandle, false);
        if r  || startsWith( matlab.internal.getcode.sfxfile(filePath),'% Error')
            resaveRequired = true;
            %@todo tWorkflowTests_17/lvlTwo_NonDirtyErrorModelResave
            %reaches here but coverage report shows it non-covered, why?
            saveSuccess = false;
        else
            resaveRequired = false;
            saveSuccess = true;
            %@todo tWorkflowTests_17/lvlTwo_NonDirtyNoErrorModelResave
            %reaches here but coverage report shows it non-covered, why?            
        end
    end
    if ~resaveRequired
        return;
    end    
    resaveBecauseOfOlderVersion  = false;
    % saving for sfx-file-rename gets superseded by saving for of sfx-codegen-older-version if both are applicable
    % we dirty the chart during open if it is from older-version
    % we cannot find the version of renamed (but not resaved file) directly as SFXFileReader throws error while reading such file (which, exist etc.).
    % we need this to ensure while RENAME_USING_SAVEAS_UI, we do the right thing if both rename and older-version are applicable
    if isequal(renameType, 'NO_RENAME') && chartH.Dirty && Stateflow.App.Studio.ResaveIfSavedWithOlderVersion(sfxFilePath, modelHandle, false)
        resaveBecauseOfOlderVersion = true;
    elseif ~isequal(renameType, 'NO_RENAME')
        %not safe to find the version for renamed
        if ~isequal(renameType, 'RENAME_ON_DISK')
            %required to find out only for saving using ui/cmd api
            %find out indirectly, i.e. if the original model is not fully-loaded in runtime, it means it was awaiting save because of older-version
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            resaveBecauseOfOlderVersion = ~isKey(instH.debugInfo,chartH.Machine.Name);
        end

    end

    % error case:
    % another model of same chart name but different file name is also open,
    % e.g. foo.sfx is copy-pasted to Copy_Of_foo.sfx on disk,
    %      and both models are open,
    %      but Copy_Of_foo.sfx is not saved in Stateflow yet,
    %      and user is trying to save foo.sfx.
    rt = sfroot;
    chartHs = rt.find('-isa', 'Stateflow.Chart', 'Name', fName);
    for i = length(chartHs):-1:1
        if sf('get', chartHs(i).Id, 'chart.stateflowApp.isApp') == false
            chartHs(i) = [];
        end
    end
    assert(~isempty(chartHs), 'sfx model could not be saved');
    if length(chartHs) > 1
        errId = 'MATLAB:sfx:OrigAndRenamedModelOpen';
        sldiagviewer.createStage(fName, 'ModelName', fName);
        sldiagviewer.reportError(getString(message(errId, fName)), 'MessageId', errId);
        saveSuccess = false;
        return;
    end

    %Save Optimization End
    versionInfo = Stateflow.App.Studio.versionCheck(filePath, false);

    %Actual Save Start
    [generatedCodeFileName, codeStr, debugInfo, saveSuccess] = Stateflow.App.Studio.generateCodeForModel(fName, chartH, renameType, oldModelName);
    sf('SaveSFX', modelHandle, filePath);
    rt = sfroot;
    hC = rt.find('-isa', 'Stateflow.Chart', 'Name', fName);
    if (isempty(hC))
        return;%@coverageexception @addedinteractivetest : g1911683
    end
    preserve_dirty = Simulink.PreserveDirtyFlag(machineH.Name,'blockDiagram');
    cb = ['Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance.setModelClose(''' fName ''',''' filePath ''',' num2str(chartH.Id) ')'];
    set_param(fName,'CloseFcn', cb);
    set_param(fName,'ModelBrowserVisibility','off');
    delete(preserve_dirty);

    % MW: This needs to move into C++.
    sfxPackageWriter = Simulink.loadsave.SLXPackageWriter(filePath, filePath);
    close_writer = onCleanup(@() sfxPackageWriter.close());
    cfgH = Stateflow.App.Cdr.CdrConfMgr.getInstance;    
    if ~isempty(generatedCodeFileName) && ~isequal(cfgH.testingUnhandledErrors, 'testingCorruptSFX')
        % Write the generated MATLAB code to the SFX file.
        genCodePartDef = Simulink.loadsave.SLXPartDefinition( ...
            '/code/mcode', ...
            '', ... % Parent
            'text/plain;charset=UTF-8', ... % content type
            'http://schemas.openxmlformats.org/package/2006/relationships/code/generatedcode', ...
            'GeneratedCode');
        sfxPackageWriter.writePartFromString(genCodePartDef, codeStr, 'UTF-8');
        %sf4mlversionfilePath = fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'version');
        % temp fix for version no. that got broken with snap from Bslx
        % changes
        versionInfo.modelMajorVersion = version('-release');
        versionInfo.modelMinorVersion = num2str(Stateflow.App.Utils.getVersion);
        versionInfo.userMinorVersion = num2str(str2double(versionInfo.userMinorVersion)+1);
        if (ispc) 
            versionInfo.lastModifiedBy = getenv('USERNAME');%@coverageexception gets covered on Windows
        else
            versionInfo.lastModifiedBy = getenv('USER');
        end
        assert(~isempty(versionInfo.lastModifiedBy), 'user name should not be empty');
        versionInfo.lastModifiedBy = strrep(versionInfo.lastModifiedBy, ' ', '_');
        versionInfo.lastModifiedBy = strrep(versionInfo.lastModifiedBy, newline, '_');
        sfmlversion = Simulink.loadsave.SLXPartDefinition( ...
            '/code/sfmlversion', ...
            '', ... % Parent
            'text/plain;charset=UTF-8', ... % content type
            'http://schemas.openxmlformats.org/package/2006/relationships/code/version', ...
            'sfmlversion');
        sfxPackageWriter.writePartFromString(sfmlversion, [versionInfo.modelMajorVersion ' ' versionInfo.modelMinorVersion ' '  versionInfo.userMajorVersion ' ' versionInfo.userMinorVersion ' ' versionInfo.lastModifiedBy], 'UTF-8');
        debugInfoForMatlabDebuggerPartDef = Simulink.loadsave.SLXPartDefinition( ...
            '/code/debugInfoForMatlabDebugger', ...
            '', ... % Parent
            'text/plain;charset=UTF-8', ... % content type
            'http://schemas.openxmlformats.org/package/2006/relationships/code/debugInfo1', ...
            'GeneratedCodeDebugInfoForMatlabDebugger');
        sfxPackageWriter.writePartFromString(debugInfoForMatlabDebuggerPartDef, debugInfo.MatlabDebuggerInfo, 'UTF-8');
        debugInfoForSFXRuntimePartDef = Simulink.loadsave.SLXPartDefinition( ...
            '/code/debugInfoForSFXRuntime', ...
            '', ... % Parent
            'application/vnd.mathworks.matlab.mxarray+binary', ... % content type
            'http://schemas.openxmlformats.org/package/2006/relationships/code/debugInfo2', ...
            'GeneratedCodeDebugInfoForSFXRuntime');
        sfxPackageWriter.writePartFromVariable(debugInfoForSFXRuntimePartDef, debugInfo.SFXRuntimeInfo);
        delete(close_writer);
        if resaveBecauseOfOlderVersion
            Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetChartRuntimeInfo(filePath, 'openChart');%__PERFORMANCE_SFX_BOTTLENECK_
        elseif isequal(renameType, 'RENAME_ON_DISK')
            Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetChartRuntimeInfo(filePath, 'openChart');%__PERFORMANCE_SFX_BOTTLENECK_
        elseif isequal(renameType, 'RENAME_USING_SAVEAS_CMD') || isequal(renameType, 'RENAME_USING_SAVEAS_CMD_EXPLICIT')  || isequal(renameType, 'RENAME_USING_SAVEAS_UI')
            Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetChartRuntimeInfo([oldModelName '.sfx'], 'renameClose');%__PERFORMANCE_SFX_BOTTLENECK_
            Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetChartRuntimeInfo(filePath, 'renameOpen');%__PERFORMANCE_SFX_BOTTLENECK_

        end
        Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetChartRuntimeInfo(filePath, 'saveChart');%__PERFORMANCE_SFX_BOTTLENECK_
    end
    %Actual Save End

    editor = StateflowDI.SFDomain.getLastActiveEditorForChart(chartH.id);
    if ~isempty(editor)
        studio =editor(1).getStudio();
        instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
        title = [instH.getSFXEditorTitlePrefix ': ' chartH.Name];
        studio.setStudioTitle(title);
    end
    allEditors = StateflowDI.SFDomain.getAllEditorsForChart(chartH.id);
    for i = 1:length(allEditors)
        if startsWith(allEditors(i).getStudio.getStudioTitle, Stateflow.App.Cdr.Runtime.InstanceIndRuntime.getSFXViewerTitlePrefix)
           allEditors(i).getStudio.close();
       end
    end

    if explicitRename == true
        return;
    end
    try
        instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
        if ~instH.loadedInSLXasModelReference.isKey(chartH.Name)
            return
        end
        loadedInSLXasModelReference = unique(instH.loadedInSLXasModelReference(chartH.Name));
        toBeSaved = [];
        for i = length(loadedInSLXasModelReference):-1:1
            try
                get_param(loadedInSLXasModelReference{i},'handle');
                toBeSaved = [toBeSaved '''' loadedInSLXasModelReference{i} ''' '];
            catch ME
                loadedInSLXasModelReference{i} = [];
            end
        end
        if isempty(toBeSaved)
            close_system([chartH.Name 'SFX'],0);        
            return;
        end
        answer = questdlg(['Following simulink model blocks refers to ' chartH.Name '.sfx. Do you want to update them as well.' newline 'Referred Model Blocks: ' toBeSaved],'Update Model References', 'Yes');
        switch answer
            case 'Yes'
            case 'No'
                return
            otherwise
                return;
        end
        close_system([chartH.Name 'SFX'],0);
        for i = 1:length(loadedInSLXasModelReference)
            try
                if isempty(loadedInSLXasModelReference{i})
                    continue;
                end
                Stateflow.App.Utils.loadSFXHelper(filePath, loadedInSLXasModelReference{i});
            catch
            end
        end
    catch
    end
end

% LocalWords:  vnd sfx yymmdd HHMMSS mlx mlapp SLX resaved ui Cdr mcode charset
% LocalWords:  openxmlformats generatedcode mlversionfile Bslx sfmlversion
% LocalWords:  mxarray coverageexception addedinteractivetest
