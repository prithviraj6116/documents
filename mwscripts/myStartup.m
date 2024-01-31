function myStartup
    setMATLABTitle;
%     setFileGenDir;
 sbmatlabcmdhelper
 addPaths();
 loadStateflow();
 % s = settings;

% s.matlab.desktop.DisplayScaleFactor.PersonalValue = 1 ;
end
function loadStateflow()
    % setBdocAsDocroot('current');
    % openExample('stateflow/AutomaticTransmissionUsingDurationOperatorExample');
    sfnew;
    %sf('Feature', 'SFLint',0); 
    cd ~/Downloads;
    %open_system('s1');
    bdclose('all');
end
function addPaths()
    addpath(fullfile(matlabroot,'toolbox/stateflow/tools'));
    addpath('/mathworks/devel/sandbox/ppatil/misc/matlabtools');
    addpath('//mathworks/hub/share/sbtools/matlab-cmds');
    addpath('/mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts');
    addpath('/mathworks/devel/sandbox/ppatil/misc/hubdocs/mwscripts/templateModels');
end
function sbmatlabcmdhelper()
     addpath('//mathworks/hub/share/sbtools/matlab-cmds'); rehash;
end
function setFileGenDir
    cfg=Simulink.fileGenControl('getConfig');
    cfg.CacheFolder='/home/ppatil/Downloads/mycg';
    cfg.CodeGenFolder='/home/ppatil/Downloads/mycg';
end
function setMATLABTitle
desktop = matlab.ui.container.internal.RootApp.getInstance();
desktop.Title = matlabroot;
end
function setMATLABTitleJavaDesktop
    rootDir = matlabroot;
    rootDirParts = split(rootDir,'/');
    jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    mlPID = num2str(feature('getpid'));
    jDesktop.getMainFrame.setTitle([rootDirParts{end-1} ' nw pid:'  mlPID]);

    for i = 1:length(rootDirParts)
        if startsWith(rootDirParts{i},'ppatil')
            if isequal(rootDirParts{i}, 'ppatil')
                jDesktop.getMainFrame.setTitle([rootDirParts{i+1} ' local pid:' mlPID]);
            else
                names = split(rootDirParts{i},'.');
                jDesktop.getMainFrame.setTitle([names{2} ' nw pid:'  mlPID]);
            end
            break;
        end
    end
end
function dummyFunction1
    if false
        p1=Simulink.Parameter;
        s1=Simulink.Signal;
        v1=Simulink.ValueType;
        a1=Simulink.AliasType;
        mv1=1;
        lv1=struct('ele1',1);
        lv2=2;
    end

    % slfeature('slBreakpointList', 1);
    % SimulinkDebugger.slDebugFeature(1);
    % % sf('feature','SLDebuggerIntegration',1);
    % set_param(0, 'AcceleratorUseTrueIdentifier','on');
    % set_param(0,'globalAccelVerboseBuild','on');
    % sf('feature','Interpreted code in RapidAccel and Deployed Targets',1);
    % sf('feature', 'Allow String in Interpreted code in RapidAccel and Deployed Targets', 1);
    % addpath('/mathworks/devel/sandbox/ppatil/misc/matlabtools');
    % slfeature('FMUBlockRaccelReval',1);
    return;



    slfeature('MLSysBlockRaccelReval',1);
    slfeature('UseSimulationServiceForRaccel',0);

    set_param(0, 'AcceleratorUseTrueIdentifier','on');
    set_param(0, 'GlobalUseClassicAccelMode', 'on');
    sfc('coder_options', 'forceNonJitBuild',1)

    slfeature('MLSysBlockRaccelReval',1);
    slfeature('UseSimulationServiceForRaccel',0);
    slfeature('MLSysBlockRaccelReval',1);
    slfeature('UseSimulationServiceForRaccel',1);
    addpath('/mathworks/devel/sandbox/ppatil/misc/matlabtools');
    % return;
    % mkdir('/home/ppatil/Downloads/debug1/slCache/sim');
    % mkdir('/home/ppatil/Downloads/debug1/slCache/codegen');
    % addpath('/home/ppatil/Downloads/debug1/slCache/sim');
    % addpath('/home/ppatil/Downloads/debug1/slCache');
    % addpath('/home/ppatil/Downloads/debug1/slCache/codegen');
    % set_param(0, 'CacheFolder','/home/ppatil/Downloads/debug1/slCache/sim');
    % set_param(0, 'CodeGenFolder','/home/ppatil/Downloads/debug1/slCache/codegen');
    cd ~/Downloads/;

    return;

    if contains(rootDir, 'current') && contains(rootDir, 'build') && contains(rootDir, 'pass')
        mName = rootDirParts{end-3};
    else
        if ~ispc
            c=system('sbver');
            try
                cmdWin = jDesktop.getClient('Command Window');
                jTextArea = cmdWin.getComponent(0).getViewport.getComponent(0);
            catch
                commandwindow;
                jTextArea = jDesktop.getMainFrame.getFocusOwner;
            end
            system('sbver')
            c1=char(jTextArea.getText);
            c11=split(c1(strfind(c1,'Perfect:'):end),newline);
            c2=split(c11{1},'/');
            c3=split(c2{end},newline);
            c4=c3{1};
            clc;
            mName = [ rootDirParts{end-1} ' : ' c4];
            mName = rootDirParts{end-1};
            if isequal(mName,'perfect')
                mName = rootDirParts{end-2};
            end

        else
            mName = rootDirParts{end-1};
        end

    end
    jDesktop.getMainFrame.setTitle(mName);

    return;
    % addpath(fullfile(matlabroot, 'toolbox', 'stateflow', 'tools'));
    % addpath(fullfile('/mathworks','devel','sandbox','ppatil','misc', 'matlabtools'));
    % % return;
    % gdbDebugging = false;
    % if gdbDebugging
    %     cd ~/Downloads/debug1;
    %     sf_car;
    %     bdclose all;
    %     cd(matlabroot);
    %     eval(['!source ~/.bashrc;export mypid=' num2str(feature('getpid')) ';gvim']);
    %     %sfc('coder_options', 'forceNonJitBuild',1);
    %     %slfeature('rtwcgir', 6);
    %     %cgxe('Feature', 'DebugInfo', 1);
    %     %sfc('coder_options', 'forceDebugOff', 1);
    %     %sfc('coder_options', 'debugBuilds',1)
    %     cd ~/Downloads/debug1;
    %     sf('feature', 'Pretty print CGIR logs',1);
    %     return;
    % end
    % addpath(fullfile(matlabroot, 'toolbox', 'stateflow', 'tools'));
    % addpath(fullfile('/mathworks','devel','sandbox','ppatil','misc', 'matlabtools'));
    % if isdeployed
    %     return;
    % end
    % addpath(fullfile(matlabroot, 'toolbox', 'stateflow', 'tools'));
    % addpath(fullfile('/mathworks','devel','sandbox','ppatil','misc', 'matlabtools'));
    % % return;
    % % slfeature('SimulinkToolstrip',0);
    %
    %
    %
    % opeds = com.mathworks.mlservices.MLEditorServices.getEditorApplication().getOpenEditors();
    % mlroot = matlabroot;
    % mlRootLen = length(mlroot);
    % for i = (opeds.size()-1) : -1 : 0
    %     try
    %         filepath = char(opeds.get(i).getStorageLocation().getFile().toString());
    %         if length(filepath) < mlRootLen || ~strcmp(mlroot, filepath(1:mlRootLen))
    %             opeds.get(i).close();
    %         end
    %     catch
    %     end
    % end
    % %addpath(fullfile(matlabroot, 'toolbox', 'stateflow', 'tools'));
    % %addpath(fullfile('/mathworks','devel','sandbox','ppatil','misc', 'matlabtools'));
    % % add_devutils;

    cgxe('Feature', 'evil')

    internal.cgir.Debug.enable
    slfeature('CGIRDumpPrettyPrints',0)
    slfeature('rtwcgir',6)
    sd = coder.Transform.internal.SLCGDebug

    internal.cgir.Debug.turnOnPrettyPrints()
    c=internal.cgir.Debug
    c.PrettyPrinter.PrettyPrintDir=pwd

    setpref('cgbug','AllPrettyPrints',0);
    setpref('cgbug','SLCG',0);
    setpref('cgbug','SLCC',0);
    setpref('cgbug','CGXE',0);
    setpref('cgbug','Stateflow',0);
    setpref('cgbug','SLDV',0);
    setpref('cgbug','PrettyPrinter',1);
    setpref('cgbug','GlobalScope',1);
    slfeature('CGIRDumpPrettyPrints',0)
    cgbug show on
    internal.cgir.Debug.turnOnPrettyPrints()
    c=internal.cgir.Debug
    c.PrettyPrinter.PrettyPrintDir=pwd


    return;
    %v=sf('find',sf('FunctionsIn',sf('get',sf('GetSFBlockData',gcbh),'instance.chart')),'state.name','mlfcn1')
    %v=sf('find',sf('SubstatesIn',sf('get',sf('GetSFBlockData',gcbh),'instance.chart')),'state.name','stateA')
    %v=sf('get',sf('find',sf('SubstatesIn',sf('get',sf('GetSFBlockData',gcbh),'instance.chart')),'state.name','A'),'state.simulink.blockHandle')
    %sf('get',sf('GetSFBlockData',get_param(get_param(gcbh,'ReferenceBlock'),'handle')),'instance.chart')
    %getappdata(get_param(sf('get',sf('GetSFBlockData',get_param(get_param(gcbh,'ReferenceBlock'),'handle')),'instance.sfunctionBlock'),'Object'),'SF_InstanceSpecChecksum')
end
function tempf1
    sfc('coder_options','forceNonJitBuild',1);
    sf('feature','Pretty print CGIR logs',1);
    sf('feature','Use global scope when pretty printing CGIR logs',1);
    internal.cgir.Debug.turnOnPrettyPrints();
    cgirrtwdebug=internal.cgir.Debug;
    cgirrtwdebug.PrettyPrinter.EnabledBefore=1;
    cgirrtwdebug.PrettyPrinter.EnabledAfter=1;
    cgirrtwdebug.PrettyPrinter.EnabledGlobalScope=1;
    cgirrtwdebug.PrettyPrinter.RemoveIdenticalFiles=1;
    cgirrtwdebug.TransformLogService.Enabled=1;
    cgirrtwdebug.TransformLogService.EnabledGlobalScope=1;
    cgirrtwdebug.NamePrinter.Enabled=1;
    %slfeature('rtwcgir',6);
    sf('feature','Globals to Locals',0);
    sf('feature','Local Reuse',0);
    sf('feature','Local Dead Code Enhanced',0);
    sf('feature','Globals Reuse',0);
end
