function profdiff(p1,p2,filename)
% Compares two profiler runs
% The output is a CSV file with names columns similar to those shown
% in the MATLAB profile viewer.
%
% profdiff(p1,p2); % creates profile.csv
% profdiff(p1,p2,filename);
%
% p1 and p2 are the result of calling:
%  p1 = profile('info')

if nargin<3
    filename = 'profile.csv';
end

f1 = p1.FunctionTable;
n1 = {f1.FunctionName};
t1 = [f1.TotalTime];
c1 = [f1.NumCalls];

f2 = p2.FunctionTable;
n2 = {f2.FunctionName};
t2 = [f2.TotalTime];
c2 = [f2.NumCalls];

names = union(n1,n2);

fh = fopen(filename,'wt');
closefile = onCleanup(@() fclose(fh));
fprintf(fh,'Name, TotalTime1, SelfTime1, Calls1, TotalTime2, SelfTime2, Calls2, dTotalTime, dSelfTime, dCalls\n');
[~,i1] = ismember(names,n1);
[~,i2] = ismember(names,n2);
for k=1:numel(names)
    if i1(k)
        ind = i1(k);
        totaltime1 = t1(ind);
        selftime1 = totaltime1 - sum([f1(ind).Children.TotalTime]);
        calls1 = c1(ind);
    else
        totaltime1 = 0;
        selftime1 = 0;
        calls1 = 0;
    end
    if i2(k)
        ind = i2(k);
        totaltime2 = t2(ind);
        calls2 = c2(ind);
        selftime2 = totaltime2 - sum([f2(ind).Children.TotalTime]);
    else
        totaltime2 = 0;
        selftime2 = 0;
        calls2 = 0;
    end
    dcalls = calls2 - calls2;
    dtotaltime = totaltime2 - totaltime1;
    dselftime = selftime2 - selftime1;
    name = strrep(names{k},',','_');
    fprintf(fh,'%s,%f,%f,%d,%f,%f,%d,%f,%f,%d\n',...
        name,totaltime1,selftime1,calls1,...
        totaltime2,selftime2,calls2,...
        dtotaltime,dselftime,dcalls);
end
fprintf('Done\n');


