function s = mt_getxmlstring(dom,query)

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

if nodeSet.getLength
    s = char(nodeSet.item(0).getTextContent);
else
    s = [];
end

