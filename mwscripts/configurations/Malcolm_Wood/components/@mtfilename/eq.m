function iseq = eq(A,B)
%MTFILENAME/EQ Returns true if the two files are the same AND EXIST.

iseq = strcmpi(getabsx(A),getabsx(B)) & exist(A) & exist(B);

