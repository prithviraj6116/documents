function slxModelRef = modelRefSFX(fullFilePath, ~, dialogH)
    [~,sfxModelName,~] = fileparts(fullFilePath);
    slxModelRef = [sfxModelName 'SFX'];
    source = dialogH.getDialogSource;
    block  = source.getBlock;
    blockPath = [block.Path '/' block.Name];
    cmd = ['Stateflow.App.Utils.loadSFXHelper(''' fullFilePath ''', ''' blockPath ''');'];
    rt = sfroot;
    isLoaded = ~isempty(rt.find('-isa', 'Stateflow.Machine', 'Name',slxModelRef));   
    sfxModelNameInt = [sfxModelName 'SFX_'];
    if isLoaded
        set_param(blockPath,'loadFcn', cmd);
        set_param(blockPath,'Tag', 'SFX_IN_SLX');
        Stateflow.App.Utils.addToModelRefInfo(sfxModelName, blockPath);
        return;
    end
    tempDir1=tempdir;
    copyfile(fullFilePath, fullfile(tempDir1,[sfxModelNameInt '.sfx']));
    Stateflow.App.Studio.Open(fullfile(tempDir1,[sfxModelNameInt '.sfx']),true)
    Stateflow.App.Studio.SaveAs(get_param(sfxModelNameInt,'handle'),fullfile(tempDir1,[sfxModelNameInt '.sfx']),true);
    
    
    preserve_dirty1 = Simulink.PreserveDirtyFlag(sfxModelNameInt,'blockDiagram'); %#ok<NASGU>
    set_param(sfxModelNameInt,'Tag','SFX_IN_SLX');
    chartId = sf('find','all','chart.name',sfxModelNameInt);
    sf('set', chartId,'.stateflowApp.isApp',0);
    set_param(sfxModelNameInt,'Name',slxModelRef);
    
    set_param(slxModelRef,'Tag','SFX_IN_SLX');
    Simulink.PreserveDirtyFlag(slxModelRef,'blockDiagram');
    set_param(slxModelRef, 'UnderspecifiedInitializationDetection', 'Simplified');
    set_param(blockPath,'loadFcn', cmd);
    set_param(blockPath,'Tag', 'SFX_IN_SLX');
    Stateflow.App.Utils.addToModelRefInfo(sfxModelName, blockPath)
    Stateflow.App.Utils.addInputPorts(slxModelRef,sfxModelNameInt);
end
