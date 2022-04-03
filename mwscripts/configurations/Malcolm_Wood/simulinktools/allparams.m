function allparams(block)
%ALLPARAMS - Lists the names of all parameters of a Simulink object
%
% allparams(block) % or block diagram, or line, or port
% allparams  % uses gcb (the currently selected block)
%
% The parameters of the object are listed in alphabetical order.  Where possible,
% the value is also shown.  Otherwise, the data type of the value is shown.
% Where parameters are write-only, that is also indicated.

if nargin<1 | isempty(block)
    block = gcb;
end

if isempty(block)
    error('No object specified, and no current block.');
end

% Retrieve the names of the parameters and sort them alphabetically
p = get_param(block,'ObjectParameters');
f = fieldnames(p);
f = sort(f);

% Show the name of the object
if ischar(block)
    disp(sprintf('Parameters for Simulink object %s',block));
else
    disp(sprintf('Parameters for Simulink object %s',getfullname(block)));
end
    
% Now retrieve the value of each parameter and print it.
for i=1:length(f)
    try
        v = get_param(block,f{i});
        if ischar(v)
            if any(v==10)
                % Too many lines of text.
                disp(sprintf('   %s:       <multiline string>',f{i}));
            elseif numel(v)>100
                % String too long
                disp(sprintf('   %s:       <%d-character string>',f{i},numel(v)));
            else
                disp(sprintf('   %s:       "%s"',f{i},v));
            end
        elseif isnumeric(v) & numel(v)==1
            % A numeric scalar.  Show it.
            disp(sprintf('   %s:       <%d>',f{i},v));
        else
            % Just show the data type.
            disp(sprintf('   %s:       <%s>',f{i},class(v)));
        end
    catch
        % Probably the parameter is write-only.
        disp(lasterr);
    end
end



