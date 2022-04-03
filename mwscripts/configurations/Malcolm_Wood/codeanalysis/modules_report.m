function modules_report(modules_list_file)

f = fopen(modules_list_file,'rt');
if f<0
    error('mwood:codeanalysis:fopen','Failed to oepn %s',modules_list_file);
end
closefile = onCleanup(@() fclose(f));

startdir = cd(sbroot);
restoredir = onCleanup(@() cd(startdir));

while ~feof(f)
    module = fgetl(f);
    tokens =  textscan(module,'%s','delimiter','/');
    modname = tokens{1}{end};
    cd(module);
    report = linecount_report;
    copyfile(report,fullfile(startdir,['preprocessor_counts_' modname '.csv']));
    cd(startdir);
end

end