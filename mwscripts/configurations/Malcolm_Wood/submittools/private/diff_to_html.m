function [html,link,added,deleted] = diff_to_html(filename,anchor,open_hlink,mdiff_output,success)
%diff_to_html
%
%  [html,link] = diff_to_html(filename,anchor,p4diff_output,success)
%

if ~success
    fheader = sprintf('<h3><a name="%s">%s %s</h3>\n',anchor,filename,open_hlink);
    if isempty(mdiff_output)
        html = sprintf('%s<p>No differences</p>\n',fheader);
    else
        html = sprintf('%s<p>Failed: %s</p>\n',fheader,mdiff_output);
    end
    added = 0;
    deleted = 0;
else
    [html,added,deleted] = i_to_html(filename,open_hlink,mdiff_output);
    fprintf('%s: added %d lines, deleted %d lines\n',...
        filename,added,deleted);
end

link = sprintf('<li><a href="#%s">%s</a> (+%d, -%d)',...
        anchor,filename,added,deleted);
end

%--------------------------------------------------------------------------
function [txt,added,deleted] = i_to_html(filename,open_hlink,mdiff_output)

% The line separator is character 10
diffdata = tokenize(mdiff_output,char(10));
i = 1;
while i<=numel(diffdata)
    if strncmp(diffdata{i},'diff',4)
        % Found the last line of mdiff information.  The rest is the
        % normal "diff" output.
        diffdata = diffdata(i+1:end);
        break;
    else
        i = i + 1;
    end
end

% colorManager = com.mathworks.comparisons.util.ColorManager.getInstance();
% profile = colorManager.getCurrentProfile();
% if isempty(profile)
%     profile = colorManager.getDefaultProfile();
% end
% addedcolor = profile.getRightDifferenceColor();
% deletedcolor = profile.getLeftDifferenceColor();
% addedcolor = java.lang.String.format('#%02x%02x%02x', addedcolor.getRed(), addedcolor.getGreen(), addedcolor.getBlue());
% deletedcolor = java.lang.String.format('#%02x%02x%02x', deletedcolor.getRed(), deletedcolor.getGreen(), deletedcolor.getBlue());

% addedcolor = com.mathworks.comparisons.util.ComparisonColors.getAddedColor;
% addedcolor = char(com.mathworks.comparisons.util.ComparisonColors.colorToHtmlString(addedcolor));
% deletedcolor = com.mathworks.comparisons.util.ComparisonColors.getRemovedColor;
% deletedcolor = char(com.mathworks.comparisons.util.ComparisonColors.colorToHtmlString(deletedcolor));
addedcolor='#c0ffc0';
deletedcolor='#ffc0c0';

added = 0;
deleted = 0;

header = sprintf('<h3><a name="%s">%s %s</h3>\n<pre>',matlab.lang.makeValidName(filename),filename,open_hlink);
lines = cell(size(diffdata));
for i=1:numel(diffdata)
    if strncmp(diffdata{i},'<',1)
        deleted = deleted + 1;
        lines{i} = ['<span style="background: ' deletedcolor '">' code2html(diffdata{i}) '</span>'];
    elseif strncmp(diffdata{i},'>',1)
        added = added + 1;
        lines{i} = ['<span style="background: ' addedcolor '">' code2html(diffdata{i}) '</span>'];
    else
        lines{i} = diffdata{i};
    end
end
lines = sprintf('%s\n',lines{:});
txt = sprintf('%s',header,lines,'</pre>');

end
