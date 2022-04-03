function listToComponentListXML(filename,ctb)
% Given a list of components, generates a simple ComponentList XML file.

f = fopen(filename,'w');
if f<0
    error('mwood:tools:listToComponentListXML','Failed to open %s for writing',filename);
end
fprintf(f,'<?xml version="1.0" encoding="utf-8"?>\n');
fprintf(f,'<componentList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
fprintf(f,' xsi:noNamespaceSchemaLocation="componentList.xsd">\n');

fprintf(f,'  <difference>\n');
fprintf(f,'    <intersection>\n');
fprintf(f,'        <upstream refid="mycomps"/>\n');
fprintf(f,'        <downstream refid="mycomps"/>\n');
fprintf(f,'     </intersection>\n');
fprintf(f,'    <componentSet refid="mycomps"/>\n');
fprintf(f,'  </difference>\n');

fprintf(f,'<definitions>\n');
fprintf(f,'  <componentSet id="mycomps">\n');
fprintf(f,'    <union>\n');
for i=1:numel(ctb)
    fprintf(f,'      <match name="%s"/>\n',ctb{i});
end
fprintf(f,'    </union>\n');
fprintf(f,'  </componentSet>\n');
fprintf(f,'</definitions>\n');
fprintf(f,'</componentList>\n');
fclose(f);

end