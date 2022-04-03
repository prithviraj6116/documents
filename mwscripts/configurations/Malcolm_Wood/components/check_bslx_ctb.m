function check_bslx_ctb(emailRecipients)

excludeList = {'examples/products/compiler',...
	'mcr/mcr_deps_core',
	'mcr/addins/mcr_addin_javabuilder',...
	'mcr/addins/mcr_addin_mps',...
	'mcr/addins/mcr_addin_pysdk'
};

r = cdlatest('Bslengine_integ');

bslx_ctb = readComponentList('Bslx');

bdacore_ctb = readComponentList('Bdacore_integ');

problems = setdiff(bslx_ctb,bdacore_ctb);

if ~isempty(problems)
    % Check whether we should ignore these components
    problems(ismember(problems,excludeList))=[];
end

if  isempty(problems)
    disp('CTB OK');
else
    disp('Got problems:');
    fprintf('  %s\n',problems{:});
    if (nargin == 1)
        if ~isempty(emailRecipients)
        origEmailPref = getpref('Internet','E_mail');
        setpref('Internet','E_mail','bslx_admins@mathworks.com');
        componentList = sprintf('\t%s\n',problems{:});
        messageBody = sprintf(['There are inconsistencies in the CTB lists of ',...
                                'Bslengine and Bslx that might cause the next job to fail.\n',...
                                'Bslx CTB list needs to be updated with following components: \n%s'],componentList);
        sendmail(emailRecipients,...
                 'Bslx CTB list needs updating!',...
                 messageBody);
        setpref('Internet','E_mail',origEmailPref);
        end
    end 
end   
    
delete(r);
end
