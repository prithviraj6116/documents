function [B,I,J] = unique(A)
%MTFILENAME/UNIQUE Performs "unique" on the absnames of the supplied objects
%
% [B,I,J] = unique(A)
%
% See UNIQUE
%

if length(A)>0
    f = getabsx(A);
    [f,I,J] = unique(f);
    B = A(I);
    if length(B)==0
        B = mtfilename(0);
    end
else
    B = mtfilename(0); I = []; J = [];
end


