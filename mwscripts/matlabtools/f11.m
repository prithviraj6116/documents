function f11(u)
    clc;
    fprintf(2,[newline '------------------------M Stack-------------------------------' newline]);
    disp('----');
    v=split(u,newline);
    s = '';
    for i = 1:length(v)
        w=split(v{i},'.');
        y=split(v{i},':');
        z=split(v{i},'>');
        if length(w) >=2  && length(y) >= 2
            y=split(y{2},':');
            z=split(z{2},':');
            [~,fileName,~]  = fileparts(w{1});
            link = ['<a href="matlab:opentoline(''' w{1} '.m'',' y{1} ')">' fileName '>' z{1} '</a>'];
            s = [s newline link];                
        end        
    end    
    fprintf(2,s);
    fprintf(2,[newline newline '------------------------Native Stack-------------------------------' newline]);
    nativestack
end