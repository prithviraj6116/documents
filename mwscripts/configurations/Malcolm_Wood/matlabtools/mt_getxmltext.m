function str = mt_getxmltext(dom,path)
    if ischar(dom)
        dom = xmlread(dom);
    end
    node = dom.getDocumentElement;
    path = mt_tokenize(path,'/');
    if ~strcmp(path{1},node.getTagName)
        error('mwood:tools:getxmltext','Root node name is %s.  Doesn''t match %s',...
            char(node.getTagName),path{1});
    end
    for i=2:numel(path)
        node = i_find(node,path{i});
    end
    nodelist = node.getChildNodes;
    num = nodelist.getLength;
    if num==0
        str = '';
    elseif num>1
        error('mwood:tools:extraXMLTag',node.getTagName);
    else
        str = char(nodelist.item(0).getData);
    end
end

%%%%%%%%%%%%%%%%%%%%
function child = i_find(node,tagname)

child = [];
temp = node.getFirstChild();
while ~isempty(temp)
    if isa(temp,'org.w3c.dom.Element')
        if strcmp(temp.getTagName,tagname)
            if ~isempty(child)
                dependencies.error('UnexpectedXMLTag',char(node.getTagName));
            end
            child = temp;
        end
    end
    temp = temp.getNextSibling();
end
if isempty(child)
    error('mwood:tools:NoXMLTag','No "%s" tag found',tagname);
end
end