function varargout = coverage(action,varargin)
%COVERAGE Gathers and displays information on M-code coverage
%
% Uses the MATLAB profiler internally, and has a similar interface
%
%
% COVERAGE ON
%              starts the coverage analyser and clears any previous data
% COVERAGE OFF
%              stops the coverage analyser
% COVERAGE REPORT D:\mycode
%              stops the coverage analyser (if it is running) and generates an
%              HTML report of the coverage of M-code in the specified directory.
%              This command can be run multiple times for different directories.
%              The same data will be available until the next time COVERAGE ON
%              is executed.
% 

switch action
    case 'on'
        profile on
    case 'off'
        profile off
    case 'report'
        [d,f,e] = fileparts(varargin{1});
        if isempty(d)
            varargin{1} = which(varargin{1});
            [d,f,e] = fileparts(varargin{1});
        end
        coverageInfo = coverage('info',varargin{1});
        if ~isempty(e)
            % The user has speicifed a file, not a directory.  This makes it easy.
            % Just create the report in the current working directory.
            summaryURL = mcov_html_mfile_report(coverageInfo,pwd);
            summaryURL = mcov_url_escape([pwd filesep summaryURL]);
        else
            outputpath = tempname;
            system(sprintf('mkdir %s',outputpath));
            summaryURL = mcov_html_directory_report( coverageInfo, outputpath );
            summaryURL = mcov_url_escape([outputpath filesep summaryURL]);
        end
		web( summaryURL );
        varargout{1} = summaryURL;
    case 'info'
        profileData = profile('info');
        if nargin<2
            error('Must specify a file or directory');
        end
		directory = varargin{1}; % root of directory tree for which to get coverage
		skipdirectories = {'CVS'}; % except CVS directories
        [d,f,e] = fileparts(directory);
        if ~isempty(e)
            % Oh, the user has specified an individual file, not a directory
            varargout{1} = mcov_profile2coverage(directory, profileData);
        else
            varargout{1} = mcov_directorycoverage( directory, profileData, skipdirectories );
        end
    case 'resume'
        profile('resume');
    otherwise
        error('Unknown action');
end

