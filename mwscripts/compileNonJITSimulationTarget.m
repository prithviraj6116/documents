function compileNonJITSimulationTarget(modelName)
    if (isunix)
        archMakeFilExtension = 'mku';
        archDirectory = 'glnxa64';
        archMexExtension = 'mexa64';
        archObjFileExtension = '.o';
        mexCompilerPath = fullfile(matlabroot,'bin', archDirectory, 'gmake');
        mexCompileCommand = [mexCompilerPath ' -f ' modelName '_sfun.' archMakeFilExtension  ' -j4'];
    elseif (ispc)
        archMexExtension = 'mexw64';
        archObjFileExtension = '.obj';
        mexCompileCommand = ['call ' modelName '_sfun.bat'];
    end

    modelSfMex = [modelName '_sfun.' archMexExtension];

    currDir = pwd;
    fileGenControlCfg = Simulink.fileGenControl('getConfig');
    nonJITCodeDir = fullfile(fileGenControlCfg.CacheFolder, 'slprj', '_sfprj', modelName, '_self', 'sfun', 'src');

    if exist(modelSfMex,'file') == 3
         delete(modelSfMex);
    end
    cd(nonJITCodeDir);
    if exist(modelSfMex,'file') == 3
         delete(modelSfMex);
    end
    delete(['*' archObjFileExtension]);

    system(mexCompileCommand);
    copyfile(modelSfMex,currDir);
    cd(currDir);
end

