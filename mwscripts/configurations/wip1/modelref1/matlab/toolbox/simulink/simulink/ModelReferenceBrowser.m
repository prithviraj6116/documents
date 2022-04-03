
%

%   Copyright 2012-2014 The MathWorks, Inc.

classdef ModelReferenceBrowser < FileReferenceBrowser
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = protected, SetAccess = private)
        Extensions  % cellarray of strings

        % message IDs
        BrowseFileRefsName  % string
        SelectedFileNotOnPathQString  % string
        SelectedFilePathIssueTitle  % string
        SelectedFileNotOnPathAddCurrentSession  % string
        SelectedFileNotOnPathDoNotAdd  % string
        SelectedFileNotOnPathCancel  % string
        SelectedFileExistsOnPathQString  % string

        SelectedFileHasLowerPrecedence  % string
        SelectedFileHasLowerPrecedenceDirty  % string
        SelectedFileHasHigherPrecedenceTemporarily  % string
        SelectedFilePrecedenceIssueTitle  % string
        SelectedFilePrecedenceIssueContinue  % string
        SelectedFilePrecedenceIssueCancel  % string
        SelectedFileIsLoadedWithMultipleFilesOnPath % string
    end
    
    methods
        function obj = ModelReferenceBrowser()
            % build up list of extensions
            exts = slInternal('getModelReferenceBrowseExtensions');
            extstr = '';
            for i = 1:length(exts)
                if(i > 1)
                    extstr = [extstr, ';']; %#ok<AGROW>
                end
                
                extstr = [extstr, '*', exts{i}]; %#ok<AGROW>
            end
            obj.Extensions = extstr;
            
            % message IDs
            obj.BrowseFileRefsName                         = 'Simulink:modelReference:browseMdlRefsName';
            obj.SelectedFileNotOnPathQString               = 'Simulink:modelReference:selectedMdlNotOnPathQString';
            obj.SelectedFilePathIssueTitle                 = 'Simulink:modelReference:selectedMdlPathIssueTitle';
            obj.SelectedFileNotOnPathAddCurrentSession     = 'Simulink:modelReference:selectedMdlNotOnPathAddCurrentSession';
            obj.SelectedFileNotOnPathDoNotAdd              = 'Simulink:modelReference:selectedMdlNotOnPathDoNotAdd';
            obj.SelectedFileNotOnPathCancel                = 'Simulink:modelReference:selectedMdlNotOnPathCancel';
            obj.SelectedFileExistsOnPathQString            = 'Simulink:modelReference:selectedMdlExistsOnPathQString';

            obj.SelectedFileHasLowerPrecedence             = 'Simulink:modelReference:selectedModelHasLowerPrecedence';
            obj.SelectedFileHasLowerPrecedenceDirty        = 'Simulink:modelReference:selectedModelHasLowerPrecedenceDirty';
            obj.SelectedFileHasHigherPrecedenceTemporarily = 'Simulink:modelReference:selectedModelHasHigherPrecedenceTemporarily';
            obj.SelectedFilePrecedenceIssueTitle           = 'Simulink:modelReference:selectedMdlPrecedenceIssueTitle';
            obj.SelectedFilePrecedenceIssueContinue        = 'Simulink:modelReference:selectedMdlPrecedenceIssueContinue';
            obj.SelectedFilePrecedenceIssueCancel          = 'Simulink:modelReference:selectedMdlPrecedenceIssueCancel';
            obj.SelectedFileIsLoadedWithMultipleFilesOnPath= 'Simulink:modelReference:selectedFileIsLoadedWithMultipleFilesOnPath';
        end
    end
        
    methods (Access = protected)
        function startingLocation = startingLocationForBrowseButton(~, currentModel)
            % string startingLocationForBrowseButton(ModelReferenceBrowser, string)
            startingLocation = startingLocationForModelBrowseButton(currentModel);
        end
        
        function [fileName, pathName, filterIndex] = chooseFile(~, extstr, dialogTitle, startingLocation)
            % [string, string, double] chooseFile(ModelReferenceBrowser, string, string, string)
            
            [fileName, pathName, filterIndex] = uigetfile(extstr, dialogTitle, startingLocation);
        end
        
        function postChooseFile(~, ~, fileName)
            % postChooseFile(ModelReferenceBrowser, string, string)
            
            [~, ~, ext] = fileparts(fileName);

            if (~ ( (strcmpi(ext,'.mdl')) ||...
                    (strcmpi(ext,'.slx')) ||...
                    (strcmpi(ext,'.sfx')) ||...
                    slInternal('isProtectedModelFileName', fileName)))
                % Selected File is not a Simulink model
                DAStudio.error('Simulink:modelReference:selectedFileInvalidModel', ...
                    fileName)
            end
        end
        
        function [isLoaded, loadedModelPath] = findLoadedFile(~, fileName)
            % [logical, string] findLoadedFile(ModelReferenceBrowser, string)

            [~, modelNameWithoutExt, ~] = fileparts(fileName);
            loadedModelPath = [];

            % This doesn't need to be under feature control because we will
            % have errored out before this if the feature is disabled
            protected = slInternal('isProtectedModelFileName', fileName);
            
            if protected
                % There can be no loaded model
                isLoaded = false;
            else
                loadedModel = find_system('Type','block_diagram','Name',modelNameWithoutExt);
                isLoaded = ~isempty(loadedModel);
                if isLoaded
                    % There is a model with same name loaded in memory
                    loadedModelPath = get_param(loadedModel{1},'FileName');
                end
            end
        end
        
        function value = getValueForWidget(~, fileName)
            % string getValueForWidget(ModelReferenceBrowser, string)

            % Put the whole filename, including extension, into the box
            value = fileName;
        end
        
        function files = getFilesOnPathMatchingSelectedFile(~, fileName)
            [~, modelNameWithoutExt] = fileparts(fileName);
            
            % Look for all the files on the path, then filter out either
            % protected models, or unprotected, depending on which was picked.
            filePaths = which('-all', modelNameWithoutExt);

            if slInternal('hasUnprotectedSimulinkExtension', fileName)
                filterFcn = 'hasUnprotectedSimulinkExtension';
            else
                filterFcn = 'hasProtectedSimulinkExtension';
            end
            
            simulinkFiles = cellfun(@(x) slInternal(filterFcn, x), filePaths);
            files = filePaths(simulinkFiles);
        end
    end
end

