function currentFilename = editordoc

currentFilename = matlab.desktop.editor.getActiveFilename;
if isempty(currentFilename)
    error('mwood:tools:editordoc','No file open in MATLAB Editor');
end

% desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
% editorgroup = desktop.getGroupContainer('Editor');
% if isempty(editorgroup)
%     error('mwood:tools:editordoc','No file open in Editor');
% end
% editor = editorgroup.getTopLevelAncestor;
% title = editor.getTitle;
% currentFilename = char(title.replaceFirst('Editor - ',''));
% currentFilename = strrep(currentFilename,' [Read Only]','');
% if currentFilename(end)=='*'
%     currentFilename(end) = [];
% end

end