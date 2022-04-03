function sfnew1(filename)
    [~,filename,~] = fileparts(filename);
    filename = [filename '.slx'];
    if exist(filename,'file') == 4
        error('file exists. give new name');
    end
    copyfile('/mathworks/devel/sandbox/ppatil/models/sfnew1.slx', filename);
    open_system(filename);
end