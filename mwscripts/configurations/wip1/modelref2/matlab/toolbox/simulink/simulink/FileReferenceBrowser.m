
%   Copyright 2012-2017 The MathWorks, Inc.

classdef FileReferenceBrowser
    %FILEREFERENCEBROWSER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = protected, SetAccess = private, Abstract, Dependent)
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
        function browse(obj, dialogH, tag, isSlimDialog, varargin)
            % The additional input (variable) arguments were added to the function, in
            % order to circumvent the difficulty involved in automated testing of
            % UIGETFILE.
            assert((nargin==4) || (nargin==7))

            if nargin == 4
                extstr = obj.Extensions;
                currentFileName = dialogH.getWidgetValue(tag);
                startingLocation = obj.startingLocationForBrowseButton(currentFileName);

                dialogTitle = DAStudio.message(obj.BrowseFileRefsName);
                [FileName,PathName,FilterIndex] = obj.chooseFile(extstr, dialogTitle, startingLocation);
            else
                FileName    = varargin{1};
                PathName    = varargin{2};
                FilterIndex = varargin{3};
            end

            if isequal(FilterIndex,0)
                % The user hit Cancel
                return
            end

            if isempty(dialogH)
                return
            end

            obj.postChooseFile(PathName, FileName);

            % For the PC, we will do a completely case-insensitive check
            % for the full path and file name. 
            if ispc
                platformPathCompare = @strcmpi;
            else
                platformPathCompare = @strcmp;
            end

            fullFileName = fullfile(PathName,FileName);

            % Check if a file with same name, and of relevant type, is
            % loaded in memory
            [isLoaded, loadedFilePath] = obj.findLoadedFile(FileName);
            if endsWith(FileName, '.sfx')
                fullFilePath = fullfile(PathName, FileName);
                slxModelRef = Stateflow.App.Utils.modelRefSFX(fullFilePath, isLoaded, dialogH);                
                if isSlimDialog
                    set_param(dialogH.getDialogSource.getBlock.Handle, tag, slxModelRef);
                else
                    dialogH.setWidgetValue(tag, [FileName '']);
                end
                return;
            end
                
            if isLoaded
                % There is a file with same name loaded in memory
                isLoadedAndSelectedFileSame = platformPathCompare(loadedFilePath,fullFileName);
                if ~isLoadedAndSelectedFileSame
                    % File loaded in memory and selected file are different
                    if ~isempty(loadedFilePath)
                        % The loaded file is saved somewhere on the disk
                        [~, otherFileName, otherFileExt] = fileparts(loadedFilePath);
                        DAStudio.error(obj.SelectedFileHasLowerPrecedence, FileName, fullFileName, [otherFileName otherFileExt], loadedFilePath)
                    else
                        % The loaded file is a dirty, never-been saved file
                        DAStudio.error(obj.SelectedFileHasLowerPrecedenceDirty, ...
                            FileName, fullFileName)
                    end
                end
            end

            % From here on, there is NEVER a situation when the selected
            % and loaded files are different.

            filePaths = obj.getFilesOnPathMatchingSelectedFile(FileName);

            if isempty(filePaths)
                % Selected file is UNIQUE and also does NOT reside on the
                % MATLAB path.
                isCancel = obj.resolvePathIssueForAUniqueFile(PathName,FileName);
                if(isCancel)
                    return
                end
            else
                % Use which -all with the full file name (WITH EXTENSION)
                % for this since we don't want to consider loaded models.
                % Using just the base name (as was done above for
                % filePaths), will return loaded models in the list.
                isSelectedFileOnPath = any(cellfun(@(x) platformPathCompare(x, fullFileName), which('-all', FileName)));
                
                doTheCheck = false;
                if isSelectedFileOnPath
                    % If there's only one matching file on the path, we're
                    % good to go and can use the choice since it is on the
                    % path and the only one.  If there's more than one file
                    % on the path that matches, we need to do some extra
                    % checks.
                    if(length(filePaths) > 1)
                        if(~ isLoaded)
                            % If the model is not loaded, we can tell if it
                            % is first on the path or not.  If it is first
                            % on the path, use it.  Otherwise, do the extra
                            % check below.
                            isSelectedFileFirstOnPath = platformPathCompare(filePaths{1}, fullFileName);
                            doTheCheck = ~isSelectedFileFirstOnPath;
                        else
                            % If the model is loaded, we can't tell, if it
                            % first on the path or not (because of how
                            % which -all treats loaded block diagrams).
                            % Generate a warning.
                            [~, otherFileName, otherFileExt] = fileparts(filePaths{2});
                            isCancel = obj.warnAboutPossiblePrecedenceIssue(FileName, ...
                                                                            fullFileName, ...
                                                                            [otherFileName otherFileExt], ...
                                                                            filePaths{2});
                            if(isCancel)
                                return
                            end
                         end
                    end
                else
                    isAnyModelOnPathInCurrDir = any(cellfun(@(x) platformPathCompare(fileparts(x), pwd), filePaths));
                    
                    % Other models with same name exist ON the path and
                    % selected model is NOT on the path
                    if ~isAnyModelOnPathInCurrDir
                        % Another model with same name is NOT in the
                        % current directory
                        isCancel = obj.resolvePathIssueForMultipleModels(PathName,FileName);
                        if(isCancel)
                            return
                        end
                    else
                        % Another model with same name is IN the current
                        % directory.  We need to do an extra precedence
                        % check
                        doTheCheck = true;
                    end
                end
                
                if doTheCheck
                    if ~isLoaded
                        % There is no model (with same name as selected
                        % model) loaded in memory
                        [~, otherFileName, otherFileExt] = fileparts(filePaths{1});
                        DAStudio.error(obj.SelectedFileHasLowerPrecedence, ...
                                       FileName, fullFileName, [otherFileName otherFileExt], ...
                                       filePaths{1})
                    else
                        % The selected model is loaded in memory.  We know that there must
                        % be at least two files with this name on the path, because:
                        %
                        %   1. The model is loaded and the user has picked the file that
                        %   is loaded.  Otherwise, we would have hit an error such as
                        %   SelectedFileHasLowerPrecedence
                        %
                        %   2. The model is not on the path because isSelectedFileOnPath 
                        %   must be false.
                        %
                        %   3. There must be a file of the same name in the current directory
                        %   because isAnyModelOnPathInCurrDir is true.
                        [~, otherFileName, otherFileExt] = fileparts(filePaths{2});
                        isCancel = obj.resolvePrecedenceIssue(FileName, ...
                                                              fullFileName, ...
                                                              [otherFileName otherFileExt],...
                                                              filePaths{2});
                        if(isCancel)
                            return
                        end
                    end
                end
            end

            % Finally set the value
            value = obj.getValueForWidget(FileName);
            
            if isSlimDialog
                set_param(dialogH.getDialogSource.getBlock.Handle, tag, value);
            else
                dialogH.setWidgetValue(tag, value);
            end
        end
    end
        
    methods (Access = protected)
        function isCancel = resolvePathIssueForAUniqueFile(obj,PathName,FileName)
            % This function brings up a question dialog which will allow a
            % user to add the selected file's path to the MATLAB path, or
            % not add the path or cancel the operation. This function
            % should be invoked when the selected file's name is unique.

            isCancel = false;

            questDlgMsg     = DAStudio.message(obj.SelectedFileNotOnPathQString, fullfile(PathName,FileName));
            questDlgTitle   = DAStudio.message(obj.SelectedFilePathIssueTitle);
            addPathMsg      = DAStudio.message(obj.SelectedFileNotOnPathAddCurrentSession);
            doNotAddPathMsg = DAStudio.message(obj.SelectedFileNotOnPathDoNotAdd);
            cancelMsg       = DAStudio.message(obj.SelectedFileNotOnPathCancel);

            choice = questdlg(questDlgMsg, questDlgTitle, ...
                addPathMsg, doNotAddPathMsg, cancelMsg, ...
                cancelMsg);

            if strcmp(choice, addPathMsg)
                % Add path
                addpath(PathName)
            elseif strcmp(choice, cancelMsg) || isempty(choice)
                % Cancel (or Closed the dialog)
                isCancel = true;
            end
        end
        
        function isCancel = resolvePathIssueForMultipleModels(obj,PathName,FileName)
            % This function brings up a question dialog which will allow a
            % user to add the selected file's path to the MATLAB path, or
            % not add the path or cancel the operation. This function
            % should be invoked when the selected file's name is NOT
            % unique, that is, other files with the same name exist on the
            % path.

            isCancel = false;

            questDlgMsg     = DAStudio.message(obj.SelectedFileExistsOnPathQString, fullfile(PathName,FileName));
            questDlgTitle   = DAStudio.message(obj.SelectedFilePathIssueTitle);
            addPathMsg      = DAStudio.message(obj.SelectedFileNotOnPathAddCurrentSession);
            doNotAddPathMsg = DAStudio.message(obj.SelectedFileNotOnPathDoNotAdd);
            cancelMsg       = DAStudio.message(obj.SelectedFileNotOnPathCancel);

            choice = questdlg(questDlgMsg, questDlgTitle, ...
                addPathMsg, doNotAddPathMsg, cancelMsg, ...
                cancelMsg); 

            if strcmp(choice, addPathMsg)
                % Add path
                addpath(PathName)
            elseif strcmp(choice, cancelMsg) || isempty(choice)
                % Cancel (or Closed the dialog)
                isCancel = true;
            end
        end

        function isCancel = resolvePrecedenceIssue(obj, ...
                selFileName,selFullFileName,otherFileName,otherFullFileName)
            % This function brings up a question dialog which will allow a
            % user to continue or cancel the operation. This function
            % should be invoked when the selected file has the highest
            % precedence but has a lower PATH precedence.

            isCancel = false;

            questDlgMsg     = DAStudio.message(obj.SelectedFileHasHigherPrecedenceTemporarily, ...
                selFileName, selFullFileName, otherFileName, otherFullFileName);
            questDlgTitle   = DAStudio.message(obj.SelectedFilePrecedenceIssueTitle);
            continueMsg     = DAStudio.message(obj.SelectedFilePrecedenceIssueContinue);
            cancelMsg       = DAStudio.message(obj.SelectedFilePrecedenceIssueCancel);

            choice = questdlg(questDlgMsg, questDlgTitle, ...
                continueMsg, cancelMsg, ...
                cancelMsg);

            if strcmp(choice, cancelMsg) || isempty(choice)
                % Cancel (or Closed the dialog)
                isCancel = true;
            end
        end
        
        
        
        
        function isCancel = warnAboutPossiblePrecedenceIssue(obj, ...
                selFileName,selFullFileName,otherFileName,otherFullFileName)
            % This function brings up a question dialog which will allow a
            % user to continue or cancel the operation. This function
            % should be invoked when the selected file has the highest
            % precedence and there is more than one file on the path.

            isCancel = false;

            questDlgMsg     = DAStudio.message(obj.SelectedFileIsLoadedWithMultipleFilesOnPath, ...
                selFileName, selFullFileName, otherFileName, otherFullFileName);
            questDlgTitle   = DAStudio.message(obj.SelectedFilePrecedenceIssueTitle);
            continueMsg     = DAStudio.message(obj.SelectedFilePrecedenceIssueContinue);
            cancelMsg       = DAStudio.message(obj.SelectedFilePrecedenceIssueCancel);

            choice = questdlg(questDlgMsg, questDlgTitle, ...
                continueMsg, cancelMsg, ...
                cancelMsg);

            if strcmp(choice, cancelMsg) || isempty(choice)
                % Cancel (or Closed the dialog)
                isCancel = true;
            end
        end
    end
    
    methods (Access = protected, Abstract)
        startingLocation = startingLocationForBrowseButton(obj, currentFileName)
            % string startingLocationForModelBrowseButton(FileReferenceBrowser, string)
            
            % get the initial folder and (optionally) filename to show in
            % the browse dialog

        [fileName, pathName, filterIndex] = chooseFile(obj, extstr, dialogTitle, startingLocation);
            % [string, string, double] chooseFile(FileReferenceBrowser, string, string, string)
            
            % bring up a browse dialog or other means of file selection;
            % return values as for uigetfile or uiputfile

        postChooseFile(obj, pathName, fileName)
            % postChooseFile(FileReferenceBrowser, string, string)
            
            % perform any needed immediate follow-up to file selection,
            % such as validating the filename or creating the specified
            % file
        
        [isLoaded, loadedFilePath] = findLoadedFile(obj, fileName)
            % [logical, string] findLoadedFile(FileReferenceBrowser, string)
            
            % find an already-loaded file which will affect resolution of
            % subsequent files of the same name, or return [false, []] if
            % no file is open or if open files do not affect resolution of
            % the current file type
            
        value = getValueForWidget(obj, fileName)
            % string getValueForWidget(FileReferenceBrowser, string)
            
            % get the result of the browse process, a value (such as a
            % filename) to be placed in the edit box or other widget
            % specified in the inputs to the 'browse' function
            
        files = getFilesOnPathMatchingSelectedFile(obj, fileName)
            % cellarray of Strings getFilesOnPathMatchingSelectedFile(FileReferenceBrowser, fileName)
            
            % Get the list of files on the path that match the given
            % fileName
    end
    
end

