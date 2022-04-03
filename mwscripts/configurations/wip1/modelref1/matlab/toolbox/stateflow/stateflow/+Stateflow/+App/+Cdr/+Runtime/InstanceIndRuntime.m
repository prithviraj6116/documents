classdef InstanceIndRuntime < handle 
%

%   Copyright 2017-2019 The MathWorks, Inc.

    properties
        %% used properties
        eMObjListerner
        debugInfo = containers.Map('KeyType', 'char', 'ValueType', 'any');
        currentInstance = [];
        currentInstanceStack = {};        
        currentInstanceName = [] %is it used?
        modelNameToFilePathMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
        chartHandleToInstanceMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
        isInUnitTestingMode = 0;
        enableStepIcons = false;
        destroyObjEventListeners = []
        subscribedToDebugEvents = false;
        numberOfOpenedSFXModels = 0;
        zoomFactors  = containers.Map('KeyType', 'char', 'ValueType', 'double');  
        currentInDebugObjectInfo = -1
        closingModels = containers.Map('KeyType', 'double', 'ValueType', 'double');
        recentSFXModels = {};
        runtimeExceptionStacks        
        currentEditor
        currentChartId
        currentStudioTag
        isWaitingForInputs = false
        allSFXModelsClosedWhileRuntimeInit = true;
        developerDebuggeringBreakpointsInGeneratedCode =  containers.Map('KeyType', 'char', 'ValueType', 'any')
        instances = {};
        currentChartIdInUnitTesting = [];
        steppingIntoSFXFromML = false;
        debugStopFileName = [];
        currentStepIsInUnitTestMode = false;
        viewerUserTagToStudioTag =  containers.Map('KeyType', 'char', 'ValueType', 'char');
        viewerStudioTagToUserTag =  containers.Map('KeyType', 'char', 'ValueType', 'char');            
        viewerStudioTagToInstance =  containers.Map('KeyType', 'char', 'ValueType', 'any');
        viewerStudioTagToEnabled =  containers.Map('KeyType', 'char', 'ValueType', 'logical');
        loadedInSLXasModelReference = containers.Map('KeyType', 'char', 'ValueType', 'any');

    end
    
    methods(Access=private)
        function obj = InstanceIndRuntime
        end        
    end
        
    methods (Static)
        function flag = isJustCleared(setValue)
            persistent justCleared
            if isempty(justCleared)
                justCleared = true;
            end
            if exist('setValue','var')
                justCleared = setValue;
            end
            flag = justCleared;
        end
        %% singleton instance
        function retval = instance
            persistent obj
            if isempty(obj)
                obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime;
                charts = sf('IdToHandle',sf('find', 'all', 'chart.stateflowApp.isApp', true));
                for i = length(charts):-1:1
                    if exist([charts(i).Name '.sfx'], 'file') == 0
                        charts(i) = [];
                    end
                end
                obj.allSFXModelsClosedWhileRuntimeInit = isempty(charts);
                Stateflow.App.Cdr.Runtime.InstanceIndRuntime.isJustCleared(true);
            else
                Stateflow.App.Cdr.Runtime.InstanceIndRuntime.isJustCleared(false);
                if obj.allSFXModelsClosedWhileRuntimeInit == false
                    charts = sf('IdToHandle',sf('find', 'all', 'chart.stateflowApp.isApp', true));%@todo navdeep, to cover this code, fix for test/toolbox/stateflow/sf_in_matlab/cdr/positive/tClearAllWarnings.m
                    obj.allSFXModelsClosedWhileRuntimeInit = isempty(charts);
                end
            end
            retval = obj;
        end
        function clearCache()
            objH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            objH.debugInfo = containers.Map('KeyType', 'char', 'ValueType', 'any');
            objH.currentInstance = [];            
            objH.currentInstanceStack = {};
            objH.currentInstanceName = []; %is it used?
            objH.modelNameToFilePathMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
            objH.chartHandleToInstanceMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
            objH.isInUnitTestingMode = 0;
            objH.enableStepIcons = false;
            objH.destroyObjEventListeners = [];
            objH.subscribedToDebugEvents = false;
            objH.numberOfOpenedSFXModels = 0;
            objH.zoomFactors = containers.Map('KeyType', 'char', 'ValueType', 'double');  
            objH.currentInDebugObjectInfo = -1;
            objH.isWaitingForInputs = false;
            objH.developerDebuggeringBreakpointsInGeneratedCode = containers.Map('KeyType', 'char', 'ValueType', 'any');
            objH.currentChartIdInUnitTesting = [];
            objH.steppingIntoSFXFromML = false;
            objH.currentStepIsInUnitTestMode = false;
            objH.viewerUserTagToStudioTag =  containers.Map('KeyType', 'char', 'ValueType', 'char');
            objH.viewerStudioTagToUserTag =  containers.Map('KeyType', 'char', 'ValueType', 'char');
%             objH.viewerStudioTagToInstance =  containers.Map('KeyType', 'char', 'ValueType', 'any');
            objH.viewerStudioTagToEnabled =  containers.Map('KeyType', 'char', 'ValueType', 'logical');
        end
        %% developer debugging related
        function setDevBreakpoint(debugMFileName, bpLineArray)
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;            
            if ~confH.generatedCodeDebugging || ~isa(bpLineArray, 'double') || ~endsWith(debugMFileName,'_sfxdebug_.m') 
                errId =  'MATLAB:sfx:debugModeError';
                error(errId ,getString(message(errId)));
            end
            if isKey(instH.developerDebuggeringBreakpointsInGeneratedCode,debugMFileName)
                instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName) = [instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName) bpLineArray];
            else
                instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName) = bpLineArray;
            end
            instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName) = unique(instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName));
            bpLineArray = instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName);
            if isempty(bpLineArray)
                return;
            end
            for i = 1:length(bpLineArray)
                dbstop('in', debugMFileName,'at', num2str(bpLineArray(i)));
            end
        end
        function clearDevBreakpoint(debugMFileName, bpLineArray)
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;            
            if ~confH.generatedCodeDebugging  || ~isa(bpLineArray, 'double') || ~endsWith(debugMFileName,'_sfxdebug_.m') 
                errId =  'MATLAB:sfx:debugModeError';
                error(errId ,getString(message(errId)));
            end
            if isKey(instH.developerDebuggeringBreakpointsInGeneratedCode,debugMFileName)
                instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName) = setdiff(instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName), bpLineArray);
                if isempty(bpLineArray)
                    bpLineArray = instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName);
                    instH.developerDebuggeringBreakpointsInGeneratedCode(debugMFileName) = [];
                end
            end
            if isempty(bpLineArray)
                return;
            end
            for i = 1:length(bpLineArray)
                dbclear('in', debugMFileName,'at', num2str(bpLineArray(i)));
            end
            
        end
         %% save dialog before closing dirty model 
        function setClosing(modelH)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            instH.closingModels(modelH) = 1;
        end
        function resetClosing(modelH)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if isKey(instH.closingModels, modelH)
                instH.closingModels.remove(modelH);
            end
        end
        function retVal = isClosing(modelH)             
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            retVal = false;
            if isKey(instH.closingModels, modelH)
                retVal = true;%@todo coverageexception addinteractivetest : for this. user tries to close dirty sfx model multiple times in quick succession
            end
        end
        
        %% symbol ui data value update related functions
        function [vStr, errorValue] = getValueStrFromValue(value)
            try
                errorValue = false;
                if isnumeric(value)
                    vStr = '';
                    [a, b] = size(value);
                    if a == 1 && b == 1
                        vStr = num2str(value);
                    else
                        for j = 1:a
                            vStr = [vStr cell2mat(arrayfun(@(x) [num2str(x) ' '], value(j,:), 'UniformOutput', false)) ';']; %#ok<AGROW>
                        end
                        vStr = ['[' vStr ']']; 
                    end
                elseif islogical(value)
                    if length(value) > 1
                        vStr = ['[ ' cell2mat(arrayfun(@(x) [num2logicalStr(x) ' '], value, 'UniformOutput', false)) ']'];
                    else
                        vStr = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.num2logicalStr(value);
                    end
                elseif ischar(value)
                    vStr = ['"' value '"'] ;
                else
                    errorValue = true;
                    [a, b] = size(value);
                    vStr = [num2str(a) 'x' num2str(b) ' ' class(value)];
                end
            catch ME %#ok<NASGU>
                errorValue = true;
                vStr = 'value not available'; %@todo i18n
            end
        end
        function updateSymbolUIDataValuesForStudio(studio,chartName, instanceH)
            assert(~isempty(studio) && isvalid(studio), 'studio must be valid');
            instH  = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            chartH = sf('IdToHandle',sfprivate('block2chart', [chartName '/' chartName]));
            dataH = sf('IdToHandle', sf('find', sf('DataIn', chartH.Id), '.scope', 'LOCAL'));
            for i = 1:length(dataH)
                dataName = dataH(i).Name;
                currentValue = instanceH.(dataName);
                [vStr, ~] = instH.getValueStrFromValue(currentValue);
                Stateflow.Interface.Panel.updateSymbolManagerValuesForStudio(studio, dataH(i).Id, vStr);
            end
        end
        function resetSymbolUIDataValuesForStudio(studio,chartName)
            assert(~isempty(studio) && isvalid(studio), 'studio must be valid');
            instH  = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            chartH = sf('IdToHandle',sfprivate('block2chart', [chartName '/' chartName]));
            dataH = sf('IdToHandle', sf('find', sf('DataIn', chartH.Id), '.scope', 'LOCAL'));
             if ~isKey(instH.debugInfo, chartName)
                 return;
             end
            debugInfo = instH.debugInfo(chartName);
            initialValueMap = debugInfo.intialDataValues;
            for i = 1:length(dataH)
                dataName = dataH(i).Name;
                vStr = initialValueMap(dataName);
                Stateflow.Interface.Panel.updateSymbolManagerValuesForStudio(studio, dataH(i).Id, vStr);
            end
        end
        function updateSymbolUIDataValues(chartName, instanceH, onlyViewer)
            if isempty(instanceH)
                return;
            end
            if ~exist('onlyViewer', 'var')
                onlyViewer = false;
            end
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            allEditors = StateflowDI.SFDomain.getAllEditorsForChart(instanceH.sfInternalObj.runtimeVar.chartId);
            for i = 1:length(allEditors)
                if ~onlyViewer && startsWith(allEditors(i).getStudio().getStudioTitle, instH.getSFXEditorTitlePrefix)
                    editorStudio = allEditors(i).getStudio();
                    instH.updateSymbolUIDataValuesForStudio(editorStudio,chartName, instanceH);
                elseif ~isempty(instanceH.sfInternalObj.runtimeVar.studio) && isvalid(instanceH.sfInternalObj.runtimeVar.studio) && isequal(allEditors(i).getStudio().getStudioTitle, instanceH.sfInternalObj.runtimeVar.studio.getStudioTitle)
                    editorStudio = allEditors(i).getStudio();
                    instH.updateSymbolUIDataValuesForStudio(editorStudio,chartName, instanceH);
                end
            end
            
        end
        function logicalStr = num2logicalStr(x)
            assert(islogical(x));
            switch x
                case true
                    logicalStr = 'true';
                case false
                    logicalStr = 'false';
            end
        end
        function resetSymbolUIDataValues(chartName)
            chartId = sf('find', 'all', 'chart.stateflowApp.isApp', true, 'chart.name', chartName);
            assert(length(chartId) == 1 && sf('ishandle',chartId), 'chart is not valid');
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            allEditors = StateflowDI.SFDomain.getAllEditorsForChart(chartId);
            for i = 1:length(allEditors)
                if startsWith(allEditors(i).getStudio().getStudioTitle, instH.getSFXEditorTitlePrefix)
                    editorStudio = allEditors(i).getStudio();
                    instH.resetSymbolUIDataValuesForStudio(editorStudio,chartName);
                end
            end
            
        end
 
        %% functions for model open/save/resave etc.
        function retVal = isModelOfSameNameAlreadyOpenInAnotherDirectory(mName, fPath)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            retVal = isKey(instH.modelNameToFilePathMap, mName) && ~strcmp(instH.modelNameToFilePathMap(mName), fPath);
        end
        function retVal = isModelOfSameNameAlreadyOpenInSameDirectory(mName, fPath)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            retVal = isKey(instH.modelNameToFilePathMap, mName) && strcmp(instH.modelNameToFilePathMap(mName), fPath);
        end
        function retVal = getLoadedSLXModelToSFXFileName(mName)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
           alreadyOpen = isKey(instH.modelNameToFilePathMap, mName);
           retVal = [];
           if alreadyOpen
               retVal = instH.modelNameToFilePathMap(mName);
           end
        end
        function retVal =  isModelOpen(mName)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            retVal = isKey(instH.modelNameToFilePathMap, mName);
        end
        function setModelOpen(mName, fPath)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            instH.modelNameToFilePathMap(mName) = fPath;
        end
        function setModelClose(mName, ~, ~)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if instH.modelNameToFilePathMap.isKey(mName)
                instH.modelNameToFilePathMap.remove(mName);
            end
        end
        
        %% breakpoint related callback functions for command line dbclear/dbstop in filename.sfx/dbclear all etc.
        % these callback are registered in toolbox/stateflow/src/stateflow/utils/SFXFileWriter.cpp
        function addBreakpointCallback(~, ~)         
        end
        function deleteBreakpointCallback(~, ~)
        end
        function deleteAllBreakpointsCallback()           
%             obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
%             if obj.numberOfOpenedSFXModels <= 0
%                 return;
%             end                
%             obj.resetChartRuntimeInfo('dummyModel.sfx', 'dbclear all');
        end        
        function bps_1 = updateSFXFileBreakpoints(chartName, clearBPFirst)
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();            
            if(confH.generatedCodeDebugging)
                nameSuffixToMangle = '_sfxdebug_.m';
            else
                nameSuffixToMangle = '';
            end
            bpList = Simulink.Debug.BreakpointList.getAllBreakpoints();
            bps_1 = [];
            conditions = {};
            for i = 1:length(bpList)
                if ~isequal(bpList{i}.modelName, chartName) || bpList{i}.isEnabled == false
                    continue;%@todo navdeep: running sfx with disabled breakpoint reaches here
                end
                conditions{end+1} = bpList{1}.condition; %#ok<AGROW>
                switch class(bpList{i}.ownerUdd)
                    case 'Stateflow.Chart'
                        bps_1 = [bps_1 0.16, 0.17]; %#ok<AGROW>
                        conditions{end+1} = bpList{1}.condition;%#ok<AGROW> %two internal breakpoints for one UI breakpoint
                    case 'Stateflow.State'
                        switch bpList{i}.tagEnum
                            case Stateflow.Debug.BreakpointTypeEnums.onStateEntry
                                bps_1 = [bps_1 str2double([num2str(bpList{i}.ownerUdd.SSIdNumber) '.4'])]; %#ok<AGROW>
                            case Stateflow.Debug.BreakpointTypeEnums.onStateDuring
                                bps_1 = [bps_1 str2double([num2str(bpList{i}.ownerUdd.SSIdNumber) '.5'])]; %#ok<AGROW>
                            case Stateflow.Debug.BreakpointTypeEnums.onStateExit
                                bps_1 = [bps_1 str2double([num2str(bpList{i}.ownerUdd.SSIdNumber) '.6'])]; %#ok<AGROW>
                        end
                    case 'Stateflow.Transition'
                        switch bpList{i}.tagEnum
                            case Stateflow.Debug.BreakpointTypeEnums.whenTransitionTested
                                bps_1 = [bps_1 str2double([num2str(bpList{i}.ownerUdd.SSIdNumber) '.2'])]; %#ok<AGROW>
                            case Stateflow.Debug.BreakpointTypeEnums.whenTransitionValid
                                bps_1 = [bps_1 str2double([num2str(bpList{i}.ownerUdd.SSIdNumber) '.3'])]; %#ok<AGROW>
                        end
                    case 'Stateflow.EMFunction'
                        bps_1 = [bps_1 str2double([num2str(bpList{i}.ownerUdd.SSIdNumber) '.' num2str(bpList{i}.lineNum)  '1'])]; %#ok<AGROW>
                end
            end
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if clearBPFirst
                dbclear([chartName nameSuffixToMangle]);
            end
            if(confH.generatedCodeDebugging)
                obj.setDevBreakpoint([chartName nameSuffixToMangle],[]);
            end

            if ~isKey(obj.debugInfo, chartName)
                return;
            end
            dbInfo = obj.debugInfo(chartName);
            dbInfo.UserBPLines = [];
            if isempty(bps_1)
                obj.debugInfo(chartName) = dbInfo;
                return;
            end
            for i = 1:length(bps_1)
                if ~isKey(dbInfo.BPToUserLine, bps_1(i))                    
                    continue;
                end                
                lineNos = dbInfo.BPToUserLine(bps_1(i));
                if ~isempty(lineNos)
                    dbInfo.UserBPLines = [dbInfo.UserBPLines lineNos(1)];
                end
            end
            for i = 1:length(dbInfo.UserBPLines)
                if isempty(conditions{i})
                    dbstop('in', [chartName nameSuffixToMangle], 'at', num2str(dbInfo.UserBPLines(i)));
                else
                    [isValid, newCondition] = Stateflow.App.Utils.lowerPropertyAccess(chartName, conditions{i}, 'this');
                    assert(isValid, 'breakpoint condition is not valid');%@todo ppatil i18n
                    %@todo ppatil verify if newCondition is actually a
                    %condition
                    dbstop('in', [chartName nameSuffixToMangle], 'at', num2str(dbInfo.UserBPLines(i)), 'if', newCondition);
                end
            end

            obj.debugInfo(chartName) = dbInfo;
        end
   
        %% current Instance Mgmt related
        function pushToCurrentInstanceStack(c)
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            obj.currentInstance = c;
            obj.currentInstanceStack{end+1} = c;
            obj.instances{end+1} = c;
        end
        function popFromCurrentInstanceStack()
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if isempty(obj.currentInstanceStack)
                return;
            end
            obj.currentInstanceStack = obj.currentInstanceStack(1:end-1);
        end
        function instance = getInstanceForChartHandle(chartHandleOrPath)
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if ischar(chartHandleOrPath)
                chartHandle = get_param(chartHandleOrPath, 'handle');
            else
                chartHandle = chartHandleOrPath;
            end
            
            if obj.chartHandleToInstanceMap.isKey(chartHandle)
                instance = obj.chartHandleToInstanceMap(chartHandle);
            else
                instance = [];
            end
        end
        
        function setInstanceForChartHandle(chartHandlePath, instance)
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;            
            chartHandlePath = get_param(chartHandlePath, 'handle');
            obj.chartHandleToInstanceMap(chartHandlePath) = instance;
        end
        
        function removeInstanceForChartHandle(chartHandle)
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if obj.chartHandleToInstanceMap.isKey(chartHandle)
                obj.chartHandleToInstanceMap.remove(chartHandle);
            end
        end
        
        %% unit testing
        function UnitTestingMode(val)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            instH.isInUnitTestingMode = val;
            instH.currentStepIsInUnitTestMode = val;
        end
        function saveCurrentCBINFO(currentEditor, currentChartId, currentStudioTag)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            instH.currentEditor = currentEditor;
            instH.currentChartId = currentChartId;
            instH.currentStudioTag = currentStudioTag;
        end
        
        %% Debug related functions
        
        function emlDebugHighlight(objH, lineNumber)
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance;
            UserData.objId = objH.Id;
            UserData.obj = objH;
            UserData.lineNo = lineNumber;
            if confH.isUnderTesting
                Stateflow.App.Cdr.Runtime.InstanceIndRuntime.emlDebugHighlightCB(UserData,[])
                return;
            end
            t= timer;
            t.TimerFc = @(x,y)Stateflow.App.Cdr.Runtime.InstanceIndRuntime.emlDebugHighlightCB(UserData,t);
            t.StartDelay = 0.4;
            t.UserData = UserData;
            t.start;
        end
        function emlDebugHighlightCB(UserData,t)            
            if ~isempty(t)
                stop(t);
                delete(t);
                clear t;
            end
            UserData.obj.view;
            sfprivate('eml_man','debugger_break', UserData.objId, UserData.lineNo);
        end
        function deleteAllDebugHighlights()
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if ishandle(instH.currentInDebugObjectInfo) && isa(instH.currentInDebugObjectInfo, 'Stateflow.Chart')
                sfprivate('set_model_status_bar', instH.currentInDebugObjectInfo.Name, '');
                sf('SetLastActiveObject', 0);
            elseif ishandle(instH.currentInDebugObjectInfo)
                sf('SetLastActiveObject', 0);
                Stateflow.internal.Debugger.addDebuggerHighlight(instH.currentInDebugObjectInfo.Id, 1, 0);                
                sfprivate('set_model_status_bar', instH.currentInDebugObjectInfo.Chart.Name, '');
                objH = sf('IdToHandle', instH.currentInDebugObjectInfo.Id);
                if isa(objH, 'Stateflow.State') && objH.IsSubchart
                    %@todo navdeep: to reach here: put breakpoints on a subcharted state
                    objH.view;
                else
                    subviewerObjH = sf('IdToHandle', objH.Subviewer.id);
                    subviewerObjH.view;
               end
            end
            instH.currentInDebugObjectInfo = -1;
        end
        function deleteDebugHighlightsExceptFor(objH)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if ishandle(instH.currentInDebugObjectInfo) && isa(instH.currentInDebugObjectInfo, 'Stateflow.Chart')
                %@todo navdeep: to reach here: put breakpoints on chart entry AND on a state, then execute till it stops at state breakpoint
                sfprivate('set_model_status_bar', instH.currentInDebugObjectInfo.Name, '');
                sf('SetLastActiveObject', 0);
            elseif ishandle(instH.currentInDebugObjectInfo) && instH.currentInDebugObjectInfo.Id ~= objH.id
                Stateflow.internal.Debugger.addDebuggerHighlight(instH.currentInDebugObjectInfo.Id, 1, 0);
                sfprivate('set_model_status_bar', instH.currentInDebugObjectInfo.Chart.Name, '');
                sf('SetLastActiveObject', 0);
            end
            instH.currentInDebugObjectInfo = -1;
        end
        function [programCounterString, statusString] = HighlightTextForDebug(filePath, chartName, objH, typeId, startI, endI, lineNoInLabel)  
            programCounterString = '';
            statusString = '';
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if instH.currentInDebugObjectInfo ~= -1 &&  isa(instH.currentInDebugObjectInfo, 'Stateflow.EMFunction')
                sfprivate('eml_man', 'debugger_break', instH.currentInDebugObjectInfo.Id,0)
            end
            instH.deleteDebugHighlightsExceptFor(objH);
            switch typeId
                case 1
                    transitionLabelStart = objH.labelString; %(1:min(5, length(objH.labelString)));
                    tagFileNameString = 'transition_testing.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointTransitionTested'));
                    statusString = getString(message('MATLAB:sfx:BeforeTestingOfTransition',  transitionLabelStart));
                case 2
                    transitionLabelStart = objH.labelString; %(1:min(5, length(objH.labelString)));
                    tagFileNameString = 'transition_testing.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointTransitionTested'));
                    statusString = getString(message('MATLAB:sfx:BeforeTestingOfTransition',  transitionLabelStart));
                case 3
                    transitionLabelStart = objH.labelString; %(1:min(5, length(objH.labelString)));
                    tagFileNameString = 'transition_cond_action.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointTransitionValid'));
                    statusString = getString(message('MATLAB:sfx:AfterActivationOfTransition',  transitionLabelStart));
                case 4
                    tagFileNameString = 'state_entry.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointStateEntry'));
                    statusString = getString(message('MATLAB:sfx:JustBeforeEnteringState',  objH.Name));
                case 5
                    tagFileNameString = 'state_during.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointStateDuring'));
                    statusString = getString(message('MATLAB:sfx:DuringState',  objH.Name));
                case 6
                    tagFileNameString = 'state_exit.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointStateExit'));
                    statusString = getString(message('MATLAB:sfx:ExitState',  objH.Name));
                case {16, 17}
                    tagFileNameString = 'state_entry.svg';
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointChartEntry'));
                    statusString = getString(message('MATLAB:sfx:EntryChart',  chartName));
            end
            if typeId == 16 || typeId == 17
                Stateflow.App.Studio.Open(filePath);
                sf('SetLastActiveObject', objH.id, tagFileNameString, programCounterString, get_param([chartName '/' chartName], 'handle'));
                sfprivate('set_model_status_bar', chartName, statusString);                
                instH.currentInDebugObjectInfo = objH;
                objH.view;
            elseif typeId == 8
                Stateflow.App.Cdr.Runtime.InstanceIndRuntime.emlDebugHighlight(objH, lineNoInLabel);
                % testing related
                confH = Stateflow.App.Cdr.CdrConfMgr.getInstance;
                if (confH.isUnderTesting && ...
                        confH.isDebuggerTesting == true &&...
                        ~isempty(confH.debuggerTestingCB))
                    sfprivate('set_model_status_bar', chartName, statusString);
                    programCounterString  = getString(message('MATLAB:sfx:BreakpointEMLFunction'));
                    statusString = getString(message('MATLAB:sfx:EMLFunction',   objH.Name));
                    
                end
                instH.currentInDebugObjectInfo = objH;
                objH.view;
            else
                endI = min(endI, length(objH.LabelString));
                Stateflow.App.Studio.Open(filePath);
                sf('SetLastActiveObject', objH.id, tagFileNameString, programCounterString, get_param([chartName '/' chartName], 'handle'));
                sfprivate('set_model_status_bar', chartName, statusString);
                Stateflow.internal.Debugger.addDebuggerHighlight(objH.id, startI, endI);
                instH.currentInDebugObjectInfo = objH;
                if isa(objH, 'Stateflow.State') && objH.IsSubchart
                    %@todo navdeep : to reach here put a breakpoint in subcharted state
                    objH.view;
                else
                    subviewerObjH = sf('IdToHandle', objH.Subviewer.id);
                    subviewerObjH.view;
                end
            end
            
        end
        
        % testing related fcn for now
        function tagType = getExpectedTagType(targetUDD, typeId)
            if(isa(targetUDD, 'Stateflow.EMFunction'))
                tagType = 'EMLFunctionBP';
                return;
            end
            tagType = '';
            % adopted from above function HighlightTextForDebug
            switch typeId
                case 1
%                     tagType = 'whenTransitionTested';
                case 2
                    tagType = 'whenTransitionTested';
                case 3
                    tagType = 'whenTransitionValid';
                case 4
                    tagType = 'onStateEntry';
                case 5
                    tagType = 'onStateDuring';
                case 6
                    tagType = 'onStateExit';
                case {16, 17}
                    tagType = 'onChartEntry';
                    
            end
        end
        
         % testing related fcn for now
        function status = getDebuggerStatus(ssid, objH, tagType, fileName, programCounterString, statusString, lineNumber)
            status = Stateflow.App.Cdr.Runtime.SFXDebuggerStatus(...
                ssid,...
                objH,...
                tagType, ...
                fileName, ...
                programCounterString, ...
                statusString, ...
                lineNumber ...
                );
        end
        
        function debugEventCallback(filePath, lineNumber, isEndOfFunction, nestingLevel)  %#ok<INUSL>
            % for use in testing infra
%             disp('white box debug event callback');
%             return;
            debuggerStatus = [];
            %disp('EnterDebuggerEventCB1');
            if nestingLevel <= 0
                return;%@todo coverageexception not sure when MATLAB debugger passes nestingLevel>0
            end
            nameSuffixToMangle = '_sfxdebug_.m';
            confMgr = Stateflow.App.Cdr.CdrConfMgr.getInstance;
            SfxfilePath = filePath;
            MfilePath = filePath;
            if(confMgr.generatedCodeDebugging)
                SfxfilePath = [filePath(1:end-length(nameSuffixToMangle)) '.sfx'];
            end
            [~, fileName, ~] = fileparts(SfxfilePath);
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            instH.debugStopFileName = fileName;
            [~, debugFileName, e] = fileparts(MfilePath);
            debugFileName = [debugFileName e];
            %todo: handle case where model from another directory with same name open
            if ~confMgr.generatedCodeDebugging
                if ~Stateflow.App.Cdr.Runtime.InstanceIndRuntime.isModelOfSameNameAlreadyOpenInSameDirectory(fileName, filePath)
                    Stateflow.App.Studio.Open(SfxfilePath);
                end
            end
            assert(endsWith(SfxfilePath,'.sfx'), 'wrong file ext');
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            bps_1 = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.updateSFXFileBreakpoints(fileName, 1);
            debugInfo = instH.debugInfo(fileName);
            if(confMgr.generatedCodeDebugging)
                if isempty(bps_1)
                    return;
                end
                if isKey(instH.developerDebuggeringBreakpointsInGeneratedCode, debugFileName)%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                    devBPs = instH.developerDebuggeringBreakpointsInGeneratedCode(debugFileName);%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                    if ~isempty(devBPs) && ~isempty(find(devBPs==lineNumber, 1))%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                        return;%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                    end%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                end%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
            end 
            if any(debugInfo.ctorStart == lineNumber) || any(debugInfo.stepStart == lineNumber)
                instH.steppingIntoSFXFromML = true;
            end
            if any(debugInfo.transitionPathEnd == lineNumber)

                %disable step icons
                instH.enableStepIcons = false;
                %set all bps  (userbp + userLineBlockStart + ctorStart + stepStart/End)
                % UserBPLines is subset of userLineBlockStart
                for i = 1:length(debugInfo.userLineBlockStart)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.userLineBlockStart(i)));
                end
                for i = 1:length(debugInfo.stepEnd)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.stepEnd(i)));
                end
                for i = 1:length(debugInfo.userFcnEndNext)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.userFcnEndNext(i)));
                end  
                for i = 1:length(debugInfo.userLines)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.userLines(i)));
                end  
                
                %dbcont
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBCONT);
            end
            if any(debugInfo.ctorStart == lineNumber) || any(debugInfo.stepStart == lineNumber) ||  any(debugInfo.userLineBlockEndNext == lineNumber) 

                %disable step icons
                instH.enableStepIcons = false;
                %set all bps  (userbp + userLineBlockStart + ctorStart + stepStart/End)
                % UserBPLines is subset of userLineBlockStart
                for i = 1:length(debugInfo.userLineBlockStart)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.userLineBlockStart(i)));
                end
                for i = 1:length(debugInfo.stepEnd)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.stepEnd(i)));
                end
                for i = 1:length(debugInfo.userFcnEndNext)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.userFcnEndNext(i)));
                end                
                %dbcont
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBCONT);
            end            
            if any(debugInfo.userFcnEndNext == lineNumber)
                %@todo navdeep: putting breakpoint on last line of eml reaches here
                %disable step icons
                instH.enableStepIcons = false;
                %clear all bps
                dbclear(MfilePath);  
                if(confMgr.generatedCodeDebugging)                
                    instH.setDevBreakpoint(MfilePath,[]);%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                end
                % set user bps
                for i = 1:length(debugInfo.UserBPLines)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.UserBPLines(i)));
                end             
                %dbstepout
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT);
            end            
            if any(debugInfo.userCustomDisp == lineNumber)
                %dbstepover
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEP);
            end  
            if any(debugInfo.userLines == lineNumber)
                %highlight
                 ssid =  debugInfo.UserLineToSSID(lineNumber);
                 typeId = debugInfo.UserLineToTypeId(lineNumber);
                 if typeId == 16 || typeId == 17
                     chartId = sfprivate('block2chart',[fileName '/' fileName]);
                     objH = sf('IdToHandle', chartId);
                 else
                     objH  = sf('IdToHandle',debugInfo.ssIdToId(ssid));
                 end
                 startI = debugInfo.UserLineToStartI(lineNumber);
                 endI = debugInfo.UserLineToEndI(lineNumber);
                 labelLineNo = debugInfo.UserLineToLabelLineNo(lineNumber);   
                 obj = instH.currentInstance.sfInternalObj.runtimeVar;
                 [programCounterString, statusString] = instH.HighlightTextForDebug(SfxfilePath, fileName, objH, typeId, startI, endI, labelLineNo);
                 sfprivate('jit_animation',obj.chartId, obj.currentHighLights, obj.instanceHandle);
                %enable step icons
                instH.enableStepIcons = true;
                
                %update the data values in symbol UI
                if isequal(fileName, class(instH.currentInstance))
                    Stateflow.App.Cdr.Runtime.InstanceIndRuntime.updateSymbolUIDataValues(fileName, instH.currentInstance);
                end
                
                if any(debugInfo.UserBPLines, lineNumber)
                    % UserBPLines is subset of userLines
                    %no-op
                end
                chartId = sfprivate('block2chart',[fileName '/' fileName]);
                if sf('get', chartId, '.locked') == 0
                    sf('set', chartId, '.locked', 1);
                end
                confH = Stateflow.App.Cdr.CdrConfMgr.getInstance;
                if (confH.isUnderTesting && ...
                        confH.isDebuggerTesting == true &&...
                        ~isempty(confH.debuggerTestingCB))
                    debuggerStatus = instH.getDebuggerStatus(ssid, objH, instH.getExpectedTagType(objH, typeId), fileName, programCounterString, statusString, labelLineNo);
                end
            end

            if any(debugInfo.userLineBlockStart == lineNumber)
                % userLineBlockStart is subset of  userLines (wrong)
                %clear all bps
                dbclear(MfilePath);
                if(confMgr.generatedCodeDebugging)
                    instH.setDevBreakpoint(MfilePath,[]);%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                end
                %set user bps
                for i = 1:length(debugInfo.UserBPLines)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.UserBPLines(i)));
                end
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEP);
            end
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance;
            if any(debugInfo.stepEnd == lineNumber)
                %disable step icons
                instH.enableStepIcons = false;
                %clear all bps
                dbclear(MfilePath);
                if(confMgr.generatedCodeDebugging)
                    instH.setDevBreakpoint(MfilePath,[]);%@todo navdeep refer to comment at the end of tWorkflowTests_14/lvlTwo_generatedCodeDebugging
                end
                %set user BP
                for i = 1:length(debugInfo.UserBPLines)
                    dbstop('in', MfilePath, 'at', num2str(debugInfo.UserBPLines(i)));
                end
                %dbstepout
                if ~instH.isInUnitTestingMode && ~confH.isUnderTesting
                    %@todo navdeep : to reach here, set confH.isUnderTesting = 0, set breakpoint in sfx,
                    %run it from command line and when stopped, do only
                    %dbstep till execution finishes. Note, if you
                    %breakpoint here, it will not work.
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT);
                elseif sf('ishandle',instH.currentChartIdInUnitTesting) && isequal(sf('get', instH.currentChartIdInUnitTesting, '.name'), fileName)
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBCONT);
                else
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT);
                end
            end
            
            if ~(...
                    any(debugInfo.ctorStart == lineNumber)            ||...
                    any(debugInfo.stepStart == lineNumber)            ||...
                    any(debugInfo.userLineBlockEndNext == lineNumber) ||...
                    any(debugInfo.userFcnEndNext == lineNumber)       ||...
                    any(debugInfo.userCustomDisp == lineNumber)       ||...
                    any(debugInfo.userLines == lineNumber)            ||...
                    any(debugInfo.userLineBlockStart == lineNumber)   ||...
                    any(debugInfo.stepEnd == lineNumber)   ...
                    )
                %dbstepout
                if ~instH.isInUnitTestingMode
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT);%@todo navdeep : to reach here, set breakpoint in sfx, run it from command line and when stopped, do dbstepout
                elseif sf('ishandle',instH.currentChartIdInUnitTesting) && isequal(sf('get', instH.currentChartIdInUnitTesting, '.name'), fileName)
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBCONT);
                else
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT);%@todo navdeep : to reach here, set breakpoint in sfx, run it from UI and when stopped, do dbstepout
                end
            end
            
            % Testing Hook
            if confH.isUnderTesting && ...
                    confH.isDebuggerTesting == true &&...
                    ~isempty(confH.debuggerTestingCB)
                
                % this is special if for testing api calls Reset() or
                % GetActiveStates(), to test dbstpe-in should not go inside
                % internal code
                if confH.debuggerTestingCB.callingObj.isSFXObjectMethodTesting
                    confH.debuggerTestingCB.fcn(confH.debuggerTestingCB.callingObj, confH.debuggerTestingCB.userData, debuggerStatus);
                    return;
                end
                
                if any(debugInfo.userLines == lineNumber)
                    confH.debuggerTestingCB.fcn(confH.debuggerTestingCB.callingObj, confH.debuggerTestingCB.userData, debuggerStatus);
                end
                return;
            end

        end
        function subscribeToDebugEvents
            %disp('subscribe');
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();
            if(confH.generatedCodeDebugging)
                instH.subscribedToDebugEvents = true;                
            elseif instH.subscribedToDebugEvents == false
                instSH = Stateflow.App.Cdr.RuntimeShared.InstanceIndRuntime.instance;
                currentDir = pwd;
                cd(fullfile(matlabroot,'toolbox/shared/stateflow/cpp_debug'));
                debugEventCallbackSFShared();
                instSH.subscribedToDebugEvents = false; 
                cd(currentDir);
                instH.subscribedToDebugEvents = true;
                sf('subscribeToDebugEvents', '.sfx', 'Stateflow.App.Cdr.Runtime.InstanceIndRuntime.debugEventCallback');
            end
        end
        function collectDebugInfoHelper(sfxFilePath)
            %disp(['collectinfo for ' filePath]);
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            [~, fileName, extName] = fileparts(sfxFilePath);
            assert(isequal(extName, '.sfx'));
            sfxFileContents = Simulink.loadsave.SLXPackageReader(sfxFilePath);
            debugInfo = sfxFileContents.readPartToVariable('/code/debugInfoForSFXRuntime');
            debugInfo.ssIdToId = instH.calculate_ids_ssid_mappings(fileName);
            instH.debugInfo(fileName) = debugInfo;
            %todo: keep user breakpoints after model resave and set them again if valid or else delete those invalid
            %instH.updateSFXFileBreakpoints()
        end
        function retVal = calculate_ids_ssid_mappings(sfxChartName)
            chartId = sfprivate('block2chart',[sfxChartName '/' sfxChartName]);
            ssIdToId = containers.Map('KeyType', 'double', 'ValueType', 'double');

            states = sf('get',chartId,'chart.states');
            transitions = sf('get',chartId,'chart.transitions');
            junctions = sf('get',chartId,'chart.junctions');
            for i=1:length(states)
                ssId = sf('get',states(i),'.ssIdNumber');
                ssIdToId(ssId) = states(i);
            end
            for i=1:length(transitions)
                ssId = sf('get',transitions(i),'.ssIdNumber');
                ssIdToId(ssId) = transitions(i);
            end
            for i=1:length(junctions)
                ssId = sf('get',junctions(i),'.ssIdNumber');
                ssIdToId(ssId) = junctions(i);
            end
            retVal = ssIdToId;
        end
        function val = isStateflowAppInDebugMode(~)
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            val = instH.enableStepIcons;
        end         
        function dbstepover(~,~)
            com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEP)
        end
        function dbstepin(~,~)
            com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPIN)
        end
        function dbstepout(~,~)
            com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT)
        end
        function dbcont(~,~)
            com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBCONT)
        end
        function dbquit(chartName, ~)            
            instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if ~exist('chartName', 'var')
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBQUIT)
                instH.isInUnitTestingMode = 0;
                instH.currentChartIdInUnitTesting = [];
                instH.deleteAllDebugHighlights();
                instH.enableStepIcons = false;                
                instH.popFromCurrentInstanceStack();
                instH.currentInstance = [];
                return;
            end
            if instH.isInUnitTestingMode
                chartId = sfprivate('block2chart',[chartName '/' chartName]);
                if sf('get', chartId, '.locked') == 1
                    sf('set', chartId, '.locked',0);%@todo navdeep to reach here set breakpoint in a nested chart, execute from UI of main chart and when stopped in nested chart, do dbquit
                end
                instH.isInUnitTestingMode = 0;
                instH.currentChartIdInUnitTesting = [];
            end
            Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetSymbolUIDataValues(chartName);
            instH.deleteAllDebugHighlights();
            instH.popFromCurrentInstanceStack();
            instH.currentInstance = [];
            wasInDebugMode = instH.enableStepIcons;
            instH.enableStepIcons = false;
            if wasInDebugMode
                %@todo navdeep: to reach here dbquit from UI while stopped at breakpoint during unit-testing
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBQUIT)
            end 
        end
        %%get recently opened sfx charts g1870561
        function retVal = getRecentlyOpenSFXModels()
%             sl_refresh_customizations;
            objH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            objH.recentSFXModels = unique(objH.recentSFXModels);
            retVal = objH.recentSFXModels;
        end
        %% temporary fix for 1871128, permanent fix required changing zoom factor to dirty the sfx chart in the studioApp/sfeditor.cpp
        function saveZoomFactor(chartName)
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            rt = sfroot;
            sfxMachines = rt.find('-isa', 'Stateflow.Machine', 'Name', chartName);
            if ~isempty(sfxMachines)
                sfxCharts = sf('ChartsOf', sfxMachines.Id);
            end
            if length(sfxCharts) == 1
                obj.zoomFactors(chartName) = sf('get', sfxCharts, 'chart.zoomFactor');
            end
        end
        function retVal =  isZoomFactorChanged(chartName)
            retVal = false;
            obj = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            if isKey(obj.zoomFactors, chartName)
                rt = sfroot;
                sfxMachines = rt.find('-isa', 'Stateflow.Machine', 'Name', chartName);
                if ~isempty(sfxMachines)
                    sfxCharts = sf('ChartsOf', sfxMachines.Id);
                end
                if length(sfxCharts) == 1
                    retVal = sf('get', sfxCharts, 'chart.zoomFactor') ~= obj.zoomFactors(chartName);
                end
            end
        end
        
        
        %% callbacks from shared runtime for error management
        function throwWarning(chartName, errId, msg)
             instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
             if instH.isModelOpen(chartName) && instH.isInUnitTestingMode == true
                 sldiagviewer.createStage(chartName, 'ModelName', chartName);
                 sldiagviewer.reportWarning(msg, 'MessageId', errId);
             else
                 oldWarningStatus = warning('backtrace');
                 warning('off', 'backtrace');
                 warning(errId,msg);
                 warning(oldWarningStatus.state, 'backtrace');
             end
        end
        %% temporalOperatorCallbackRouter
        %this allows user to protect against error message because of timers when parent object is cleared or deleted        
        function temporalOperatorCallbackRouter(src, ~)
            try  
                instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
                instH.currentStepIsInUnitTestMode = true; %@todo make it true only if timer callback is part of UI test.
                chartName = [];
                if isa(src.UserData.sfxInstance, 'handle') && isvalid(src.UserData.sfxInstance)
                    chartName = src.UserData.sfxInstance.sfInternalObj.runtimeVar.chartName;
                    timer_callback(src.UserData.sfxInstance, src.UserData.eventsActivated)
                end
            catch ME
                 if ~isempty(chartName) && isvalid(src)
                    if instH.isInUnitTestingMode == true
                        if ~isempty(instH.currentChartIdInUnitTesting) && sf('ishandle', instH.currentChartIdInUnitTesting)                            
                            Stateflow.App.Studio.ToolBars('handleRuntimeExceptionInUnitTestingSFApp',instH.currentEditor, instH.currentChartId, instH.currentStudioTag, ME);%@todo navdeep : fix tWorkflowTests_10.m>lvlTwo_timerRuntimeErrorDuringUIWhileModelIsOpen to cover this line
                        else
                            objExists = evalin('base', sprintf('exist(''my_%s'', ''var'')', chartName));
                            if objExists
                                evalin('base', sprintf('delete(my_%s)', chartName));
                                evalin('base', sprintf('clear my_%s', chartName));
                            end
                            instH.isInUnitTestingMode = false;
                            instH.currentChartIdInUnitTesting = [];
                        end
                    else
                        if ispc
                            fprintf(2,strrep([getReport(ME) newline],'\','\\')); %@coverageexception gets covered on Windows
                        else
                            fprintf(2,[getReport(ME) newline]);
                        end
                        confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();
                        if confH.isUnderTesting
                            confH.debuggerTestingCB.timerME = ME;
                        end
                     end
                 end
            end
        end
        
        %% model save/open/reopen/close callbacks
        function closeChartCallback(r, ~)
            sfxFilePath = getappdata(r,'sfxFilePath');
            Stateflow.App.Cdr.Runtime.InstanceIndRuntime.resetChartRuntimeInfo(sfxFilePath, 'closeChart')
        end        
        function resetChartRuntimeInfo(sfxFilePath, action)
            [dir, fileName, ext] = fileparts(sfxFilePath);
            assert(strcmp(ext, '.sfx'));
            mFilePath = fullfile(dir, [fileName '']);
            try
                removeBPOnChart = false;
                removeBPinGeneratedFile = false;
                removeHighLights = false;
                collectSFXDebugInfo = false;
                deleteSFXDebugInfo = false;
                subscribeToDebugEvents = false;
                instH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
                switch action                    
                    case 'newChartObjectCreation'
                    case 'newStep'
                    case 'renameOpen'
                        removeBPOnChart = true;
                        removeBPinGeneratedFile = true; 
                        removeHighLights = true;
                        collectSFXDebugInfo = true;
                        subscribeToDebugEvents = true;
                        instH.numberOfOpenedSFXModels = instH.numberOfOpenedSFXModels + 1;
                        instH.recentSFXModels = [instH.recentSFXModels; sfxFilePath];
                    case 'openChart'
                        removeBPOnChart = true;
                        removeBPinGeneratedFile = true;
                        removeHighLights = true;
                        collectSFXDebugInfo = true;
                        subscribeToDebugEvents = true;
                        instH.numberOfOpenedSFXModels = instH.numberOfOpenedSFXModels + 1;
                        instH.saveZoomFactor(fileName);
                        instH.recentSFXModels = [instH.recentSFXModels; sfxFilePath];
                    case {'renameClose'}
                        removeBPOnChart = true;
                        removeBPinGeneratedFile = true;
                        removeHighLights = true;
                        deleteSFXDebugInfo = true;
                        instH.numberOfOpenedSFXModels = instH.numberOfOpenedSFXModels - 1;
                    case {'closeChart'}
                        removeBPOnChart = true;
                        removeBPinGeneratedFile = true;
                        removeHighLights = true;
                        deleteSFXDebugInfo = true;
                        instH.numberOfOpenedSFXModels = instH.numberOfOpenedSFXModels - 1;
                    case 'saveChart'
                        removeBPOnChart = false;
                        removeBPinGeneratedFile = true;
                        removeHighLights = true;
                        collectSFXDebugInfo = true;
                        instH.deleteAllDebugHighlights();
                        instH.saveZoomFactor(fileName);                        
                end
                if subscribeToDebugEvents
                    instH.subscribeToDebugEvents();
                end
                if collectSFXDebugInfo
                    instH.collectDebugInfoHelper(sfxFilePath)                    
                end
                if deleteSFXDebugInfo && isKey(instH.debugInfo,fileName)
                    instH.debugInfo.remove(fileName);
                end
                if removeBPinGeneratedFile && exist(mFilePath, 'file')
                    evalin('base', ['dbclear in ''' mFilePath ''';'])
                end         
                chartName  = fileName;
                rt=sfroot;
                sfxMachines = rt.find('-isa', 'Stateflow.Machine', 'Name', chartName);
                r=[];
                if ~isempty(sfxMachines)
                    tempChart = sfxMachines.find('-isa', 'Stateflow.Chart');
                    if ~isempty(tempChart) && sf('get', tempChart.Id, 'chart.stateflowApp.isApp')
                        r = tempChart;
                    end
                end
                
                if removeBPOnChart && ~isempty(r)
                    Stateflow.Debug.clear_all_breakpoints_in_chart(r.Id);
                end
                
                if removeHighLights
                    if ~isempty(r)
                        r1 = sf('IdToHandle',r.Id);
                    else
                        r1=[];
                    end
                    sf('SetLastActiveObject', 0);
                    if ~isempty(r1)
                        sfprivate('jit_animation',r1.id, [], get_param(r1.Path, 'handle'));
                    end
                end
                switch action
                    case 'renameOpen'
                        setappdata(r,'sfxFilePath',sfxFilePath)
                    case 'openChart'
                        setappdata(r,'sfxFilePath',sfxFilePath)
                        funH = @Stateflow.App.Cdr.Runtime.InstanceIndRuntime.closeChartCallback;
                        instH.destroyObjEventListeners  = [instH.destroyObjEventListeners handle.listener(r, 'ObjectBeingDestroyed', @(a,b)funH(a,b))];                        
                    
                    
                    
                        chartEditors = StateflowDI.SFDomain.getAllEditorsForChart(r.Id);
                        studio1 = chartEditors(1).getStudio;
                        title = [instH.getSFXEditorTitlePrefix ': ' chartName];
                        studio1.setStudioTitle(title);
            
                    
                    
                    case 'closeChart'
                        if ~isempty(r) && ~isempty(instH.currentChartIdInUnitTesting) && isequal(r.id, instH.currentChartIdInUnitTesting)
                            chartH = sf('IdToHandle', r.id);
                            if chartH.Locked == true
                                chartH.Locked = false;
                            end
                            objExists = evalin('base', sprintf('exist(''my_%s'', ''var'')', chartName));
                            if objExists
                                evalin('base', sprintf('delete(my_%s)', chartH.Name));
                                evalin('base', sprintf('clear my_%s', chartH.Name));
                            end
                            instH.currentChartIdInUnitTesting = [];
                            instH.isInUnitTestingMode = false;
                            if instH.enableStepIcons
                                instH.enableStepIcons = false;
                                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBQUIT)
                            end
                       end
                end
                confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();                
                if isequal(confH.testingUnhandledErrors,'modelCB')
                    disp(nonExistingVar);
                end
            catch ME %#ok<NASGU>
                %model callbacks are fail-silent
            end
        end
        function switchToWhiteboxHelper(UserData, t)
            stop(t)
            delete(t);
            clear t;
            fileName = UserData.fileName;
            lineNumber = UserData.lineNumber;
            edit(fileName);
            [~,f,~] = fileparts(fileName);
            objSH = Stateflow.App.Cdr.RuntimeShared.InstanceIndRuntime.instance;
            objH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
            dbInfo = objH.debugInfo(f);
            if lineNumber == dbInfo.userLineBlockStart(1) + 1 ||  lineNumber == dbInfo.userLineBlockStart(2) + 1
                if ~isempty(objSH.currentInstance)
                    objSH.currentInstance{1}.sfInternalObj.runtimeVar=Stateflow.App.Cdr.Runtime.Animation(UserData.fileName,1,1,[f '/' f]);
                    objH.subscribeToDebugEvents();
                    objH.debugEventCallback(UserData.fileName, UserData.lineNumber, false, 1);
                    dbclear(UserData.fileName);
                else
                    dbclear(UserData.fileName);
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEPOUT);
                    com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBSTEP);
                end
            else
                dbstop('in', fileName, 'at', num2str(dbInfo.userLineBlockStart(1) + 1));
                dbstop('in', fileName, 'at', num2str(dbInfo.userLineBlockStart(2) + 1));
                com.mathworks.mlservices.MatlabDebugServices.dbCommandNoEcho(com.mathworks.mlservices.MatlabDebugServices.DBCONT);
            end
        end
        
        function prefix =  getSFXViewerTitlePrefix()
            prefix = 'SFX Viewer(read-only)';
        end

        function switchToWhitebox(fileName, lineNumber)
            t= timer;
            UserData.fileName = fileName;
            UserData.lineNumber = lineNumber;
            t.TimerFcn = @(x,y)Stateflow.App.Cdr.Runtime.InstanceIndRuntime.switchToWhiteboxHelper(UserData,t);
            t.StartDelay = 0.3;
            t.start;
        end
        function prefix =  getSFXEditorTitlePrefix()
            prefix = 'SFX Editor ';
        end
       
       
    end

end

% LocalWords:  userbp
% LocalWords:  userbp sfx navdeep cdr sfxdebug coverageexception ppatil
% LocalWords:  addinteractivetest ui resave utils sldiagviewer Mgmt prithviraj
% LocalWords:  svg BP dbstepout dbstepover collectinfo sfeditor
% LocalWords:  userbp sfx sfxdebug ui resave utils Cdr sldiagviewer svg BP
% LocalWords:  dbstepout dbstepover unsubscribe collectinfo sfeditor
