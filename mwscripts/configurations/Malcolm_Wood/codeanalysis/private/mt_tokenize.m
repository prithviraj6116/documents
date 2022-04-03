function tokens = mt_tokenize(str,character)
%MT_TOKENIZE Splits a string into a cell array of substrings
%
% tokens = mt_tokenize(str)
% tokens = mt_tokenize(str,character)
%
% Uses strtok to split the specified string into a cell
% array of substrings, where the substrings are identifies
% by the specified character or by whitespace if no
% character is specified.

tokens = {};
if nargin<2
    [temp,remainder] = strtok(str);
    while ~isempty(temp)
        tokens = [ tokens ; {temp} ];
        [temp,remainder] = strtok(remainder);
    end
else
    [temp,remainder] = strtok(str,character);
    while ~isempty(temp)
        tokens = [ tokens ; {temp} ];
        [temp,remainder] = strtok(remainder,character);
    end
end

