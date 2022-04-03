classdef componentReader < handle
   properties
       componentName;
       dependsOn = 'not loaded';
       allUpstreamComponents = 'not loaded';
       root = matlabroot;
       isPrincipal = false;
       isBuildTool = false;
   end
   methods
       
       %-------------------------
       function obj = componentReader(componentname)
           obj.componentName = componentname;
       end


        %--------------------------------------------------------------------------
        function loadComponent(obj)
            dom = readComponentFile(obj);
            
            xpathFactory = javax.xml.xpath.XPathFactory.newInstance();
            xpathObj = xpathFactory.newXPath();

            query = '//dependsOn/componentDep/@name';
            nodeSet = xpathObj.evaluate(query, dom, javax.xml.xpath.XPathConstants.NODESET);
            comps = cell(nodeSet.getLength,1);
            for i=1:nodeSet.getLength
                comps{i} = char(nodeSet.item(i-1).getTextContent);
            end
            obj.dependsOn = comps(:);

            obj.isPrincipal = strcmp(mt_getxmlstring(dom,'//componentType/@principal'),'true');
            obj.isBuildTool = strcmp(mt_getxmlstring(dom,'//componentType/buildtool/text()'),'true');
        end
        
        %-----------------------------------------------------------------
        function [cpp_lines,java_lines,m_lines] = getCodeCount(obj)
        % Could use this tool but it doesn't have many jobs in its database
        %infotool = '/hub/share/apps/iat/devapps/componentization/component_info/prod/bin/component_info';
        fprintf('Analysing code for component %s\n',obj.componentName);
        [cpp_files,java_files,m_files] = obj.getSourceFiles;
        fprintf('Found %d C++ files, %d Java files, %d MATLAB files\n',...
            numel(cpp_files), numel(java_files), numel(m_files));
        cpp_lines = obj.getSourceLines(cpp_files);
        java_lines = obj.getSourceLines(java_files);
        m_lines = obj.getSourceLines(m_files);
        end

        %-----------------------------------------------------------------
        function count = getSourceLines(obj,files)
        count = 0;
        for i=1:numel(files)
            count = count + linecount_database(fullfile(obj.root,files{i}));
        end
        end
        
        %-----------------------------------------------------------------
        function files = getSourceFilesByType(~,dir,ext)
        % Must already have changed to directory "dir"!
            files = find_files_by_type(ext);
            for k=1:numel(files)
                str = files{k};
                if strncmp(str,'./',2)
                    str(1:2) = [];
                end
                files{k} = fullfile(dir,str);
            end
        end
        
        %-----------------------------------------------------------------
        function [cpp_files,java_files,m_files] = getSourceFiles(obj)
            [dirs,files,excluded_dirs,excluded_files] = obj.getSCMEntries;
            fprintf('Found %d directories (%d excluded), %d named files (%d excluded)\n',...
                numel(dirs), numel(excluded_dirs), numel(files), numel(excluded_files));
            cpp_files = {};
            java_files = {};
            m_files = {};
            startdir = pwd;
            restoredir = onCleanup(@() cd(startdir));
            for i=1:numel(dirs)
                try
                    cd(fullfile(obj.root,dirs{i}));
                catch E
                    disp(E.message);
                    continue;
                end
                cpp_files = dependencies.cellcat(cpp_files,...
                    obj.getSourceFilesByType(dirs{i},'.cpp'));
                java_files = dependencies.cellcat(java_files,...
                    obj.getSourceFilesByType(dirs{i},'.java'));
                m_files = dependencies.cellcat(m_files,...
                    obj.getSourceFilesByType(dirs{i},'.m'));
            end
            delete(restoredir);
            for i=1:numel(files)
                [~,~,ext] = fileparts(files{i});
                if strcmp(ext,'.cpp')
                    cpp_files = dependencies.cellcat(cpp_files,files(i));
                elseif strcmp(ext,'.java')
                    java_files = dependencies.cellcat(java_files,files(i));
                elseif strcmp(ext,'.m')
                    m_files = dependencies.cellcat(m_files,files(i));
                end
            end
            for i=1:numel(excluded_dirs)
                d = [excluded_dirs{i} '/'];
                n = numel(d);
                exclude = strncmp(d,cpp_files,n);
                cpp_files = cpp_files(~exclude);
                exclude = strncmp(d,java_files,n);
                java_files = java_files(~exclude);
                exclude = strncmp(d,m_files,n);
                m_files = m_files(~exclude);
            end
            cpp_files = setdiff(cpp_files,excluded_files);
            java_files = setdiff(java_files,excluded_files);
            m_files = setdiff(m_files,excluded_files);
        end

        %--------------------------------------
        function [dirs,files,excluded_dirs,excluded_files] = getSCMEntries(obj)
            dom = readComponentFile(obj);
            dirnodes = dom.getElementsByTagName('dirName');
            filenodes = dom.getElementsByTagName('fileName');
            ndirs = dirnodes.getLength();
            nfiles = filenodes.getLength();
            dirs = {};
            files = {};
            excluded_dirs = {};
            excluded_files = {};
            for i=1:ndirs
                dirnode = dirnodes.item(i-1);
                dir = dependencies.readxmltext(dirnode);
                excluded = dirnode.getAttribute('excluded');
                if strcmp(excluded,'true')
                    excluded_dirs{end+1} = dir; %#ok<*AGROW>
                else
                    dirs{end+1} = dir;
                end
            end
            for i=1:nfiles
               filenode = filenodes.item(i-1);
                file = dependencies.readxmltext(filenode);
                excluded = filenode.getAttribute('excluded');
                if strcmp(excluded,'true')
                    excluded_files{end+1} = file; %#ok<*AGROW>
                else
                    files{end+1} = file;
                end
            end
        end
        
        %--------------------------------------
        function [matlab_modules,cxx_modules] = getModules(obj)
            dom = readComponentFile(obj);
            matlab_modules = {};
            cxx_modules = {};
            modules = dom.getElementsByTagName('modules');
            if ~modules.getLength
                return;
            end
            modules = modules.item(0);
            mat = modules.getElementsByTagName('matlabModules');
            if mat.getLength
                mat = mat.item(0);
                mat = mat.getElementsByTagName('module');
                nmat = mat.getLength();
                for i=1:nmat
                    matnode = mat.item(i-1);
                    matlab_modules{end+1} = dependencies.readxmltext(matnode);
                end
            end
            cxx = modules.getElementsByTagName('cxxModules');
            if cxx.getLength
                cxx = cxx.item(0);
                cxx = cxx.getElementsByTagName('module');
                ncxx = cxx.getLength();
                for i=1:ncxx
                    cxxnode = cxx.item(i-1);
                    cxx_modules{end+1} = char(cxxnode.getAttribute('name'));
                end
            end
        end

        %--------------------------------------
        function filename = getComponentFile(obj)
            filename = fullfile(obj.root,'config','components',[obj.componentName '.xml']);
        end
        
        %--------------------------------------
        function dom = readComponentFile(obj)
            filename = getComponentFile(obj);
            dom = xmlread(org.xml.sax.InputSource(filename));
        end
    end
end