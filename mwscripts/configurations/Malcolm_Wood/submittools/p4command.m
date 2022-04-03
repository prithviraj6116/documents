function output = p4command(str,varargin)
    str = sprintf(str,varargin{:});
    [status,output] = system(['p4 ' str]);
    if status
        error('mwood:p4:error','%s',output);
    end
end