function loadSFXHelper(fullFilePath, blockPath)
    [~,sfxModelName,~] = fileparts(fullFilePath);
    slxModelRef = [sfxModelName 'SFX'];
    rt = sfroot;
    sfxModelNameInt = [sfxModelName 'SFX_'];
    if ~isempty(rt.find('-isa', 'Stateflow.Machine', 'Name',slxModelRef))
    else
        tempDir1=tempdir;
        copyfile(fullFilePath, fullfile(tempDir1,[sfxModelNameInt '.sfx']));
        Stateflow.App.Studio.Open(fullfile(tempDir1,[sfxModelNameInt '.sfx']),true);
        Stateflow.App.Studio.SaveAs(get_param(sfxModelNameInt,'handle'),fullfile(tempDir1,[sfxModelNameInt '.sfx']),true);
        preserve_dirty1 = Simulink.PreserveDirtyFlag(sfxModelNameInt,'blockDiagram'); %#ok<NASGU>
        set_param(sfxModelNameInt,'Tag','SFX_IN_SLX');
        chartId = sf('find','all','chart.name',sfxModelNameInt);
        sf('set', chartId,'.stateflowApp.isApp',0);
        set_param(sfxModelNameInt,'Name',slxModelRef);
        Stateflow.App.Utils.addInputPorts(slxModelRef,sfxModelNameInt);
    end
    Stateflow.App.Utils.addToModelRefInfo(sfxModelName, blockPath);    
    set_param(slxModelRef,'Tag','SFX_IN_SLX');
    Simulink.PreserveDirtyFlag(slxModelRef,'blockDiagram');
    set_param(slxModelRef, 'UnderspecifiedInitializationDetection', 'Simplified');
    obj=get_param(get_param(blockPath,'handle'),'Object');
    obj.refreshModelBlock;    
end
