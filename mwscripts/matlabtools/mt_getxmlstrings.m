function s = mt_getxmlstrings(dom,query)

persistent xpathFactory;
persistent xpathObj;

if isempty(xpathFactory)
    xpathFactory = javax.xml.xpath.XPathFactory.newInstance();
    xpathObj = xpathFactory.newXPath();
end

if ischar(dom)
    dom = xmlread(dom);
end

nodeSet = xpathObj.evaluate(query, dom, javax.xml.xpath.XPathConstants.NODESET);

s = cell(nodeSet.getLength,1);
for i=1:nodeSet.getLength
    s{i} = char(nodeSet.item(i-1).getTextContent);
end

