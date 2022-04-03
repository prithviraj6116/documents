function c = readtextfile(mf,val)
%MTFILENAME/READTEXTFILE Returns the lines of text as a cell array of strings
%
% c = readtextfile(mf);
%
% The file must exist and be accessible or an error will be thrown.

assert(numel(mf)==1,'Exactly one file required');
hf = fopen(mf,'rt',true); % throw error on failure

% Can't use textscan here because it discards leading whitespace
%c = textscan(hf,'%s','delimiter',char(10),'whitespace','');
%c = c{1};

c = cell(1000,1);
count = 1;
while 1
    ln = fgetl(hf);
    if ~ischar(ln)
        break;
    else
        c{count} = ln;
        count = count + 1;
    end
end
if count<=1000
    c = c(1:count-1);
end

if nargin>1 && val
    c = sprintf('%s\n',c{:});
end

fclose(hf);

