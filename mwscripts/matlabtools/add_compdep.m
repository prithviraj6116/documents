function add_compdep(compdef,newcomp)

dom = xmlread(compdef);
r = dom.getDocumentElement;

nodelist = r.getElementsByTagName('dependsOn');
dep = nodelist.item(0);

newdep = dom.createElement('componentDep');
newdep.setAttribute('name',newcomp);
dep.appendChild(newdep);
p4edit(compdef);
xmlwrite(compdef,dom);
i_removeExtraNewlines(compdef);

end

function i_removeExtraNewlines(f)
    fileContents = fileread(f);
    cleanedContents = regexprep(fileContents, '\n\s*\n', '\n');
    fID = fopen(f,'wt');
    fwrite(fID, cleanedContents);
    fclose(fID);
end