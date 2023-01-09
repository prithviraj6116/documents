function compileNonJITSimulationTarget(modelName)
    fileGenControlCfg = Simulink.fileGenControl('getConfig');
    nonJITModelCodeDir = fullfile(fileGenControlCfg.CacheFolder, 'slprj', '_sfprj', modelName);
    nonJITModelCodeDirContents=dir(nonJITModelCodeDir);
    for nonJITModelMachineCodeDirIndex = length(nonJITModelCodeDirContents):-1:3
        nonJITModelMachineCodeDir = nonJITModelCodeDirContents(nonJITModelMachineCodeDirIndex);
        if nonJITModelMachineCodeDir.isdir
            if isequal(nonJITModelMachineCodeDir.name,'_self')
                machineName = modelName;
            else
                machineName = nonJITModelMachineCodeDir.name;
            end
            compileNonJITSimulationTargetForAMachine(modelName, machineName, nonJITModelMachineCodeDir.name);
        end
    end
end
function compileNonJITSimulationTargetForAMachine(modelName, machineName, machineFolderName)
    if (isunix)
        archMakeFilExtension = 'mku';
        archDirectory = 'glnxa64';
        archMexExtension = 'mexa64';
        archObjFileExtension = '.o';
        mexCompilerPath = fullfile(matlabroot,'bin', archDirectory, 'gmake');
        mexCompileCommand = [mexCompilerPath ' -f ' machineName '_sfun.' archMakeFilExtension  ' -j4'];
    elseif (ispc)
        archMexExtension = 'mexw64';
        archObjFileExtension = '.obj';
        mexCompileCommand = ['call ' modelName '_sfun.bat'];
    end

    modelSfMex = [modelName '_sfun.' archMexExtension]; 
    fileGenControlCfg = Simulink.fileGenControl('getConfig');
    nonJITCodeDir = fullfile(fileGenControlCfg.CacheFolder, 'slprj', '_sfprj', modelName, machineFolderName, 'sfun', 'src');
    currDir = pwd;

    if exist(modelSfMex,'file') == 3
         delete(modelSfMex);
    end
    cd(nonJITCodeDir);
    if exist(modelSfMex,'file') == 3
         delete(modelSfMex);
    end
    delete(['*' archObjFileExtension]);

    system(mexCompileCommand);
    if exist(modelSfMex,'file') == 3
        copyfile(modelSfMex,currDir);
    end
    cd(currDir);
end

