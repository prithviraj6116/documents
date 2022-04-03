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
% rootDir = matlabroot;
% rootDirParts = split(rootDir,'/');
% jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
% if contains(rootDir, 'current') && contains(rootDir, 'build') && contains(rootDir, 'pass')
%     mName = rootDirParts{end-3};
% else    
%     if ~ispc
%         c=system('sbver');
%         try
%             cmdWin = jDesktop.getClient('Command Window');
%             jTextArea = cmdWin.getComponent(0).getViewport.getComponent(0);
%         catch
%             commandwindow;
%             jTextArea = jDesktop.getMainFrame.getFocusOwner;
%         end
%         system('sbver')
%         c1=char(jTextArea.getText);
%         c11=split(c1(strfind(c1,'Perfect:'):end),newline);
%         c2=split(c11{1},'/');
%         c3=split(c2{end},newline);
%         c4=c3{1};
%         clc;
%         mName = [ rootDirParts{end-1} ' : ' c4];
%     else
%         mName = rootDirParts{end-1};
%     end
%     
% end
% jDesktop.getMainFrame.setTitle(mName);
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
