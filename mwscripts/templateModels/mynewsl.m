function mynewsl(modelName, specification)
    if ~exist('modelName','var')
        error('provide modelname');
    end
    if ~exist('specification','var')
        specification = 'basic';
    end
    switch (specification)
        case 'basic'
            templateModelName = 'myPPTemplate1';
    end

    [myDir,~,~] = fileparts(mfilename('fullpath'));
    templateModelPath = fullfile(myDir, [templateModelName '.slx']);
    newModelPath = fullfile(pwd,[modelName '.slx']);

    copyfile(templateModelPath, newModelPath);
    open_system(modelName);
end
