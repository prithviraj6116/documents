function addToModelRefInfo(sfxModelName, blockPath)
    instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
    if isKey(instH.loadedInSLXasModelReference,sfxModelName)
        v = instH.loadedInSLXasModelReference(sfxModelName);
    else
        v = {};
    end
    v{end+1} = blockPath;
    instH.loadedInSLXasModelReference(sfxModelName) = v;
end
