classdef ProfileDiffResults < handle
% Compares two profiler runs

    properties
       % Source profiler data.  Result of calling profile('info').
       data1
       data2
       % Union of all function names
       functionNames
       % All remaining properties are the same size as functionNames, and
       % refer to the value extracted from p1 or p2 for that function.
       
       % Index of function name i in p1 (zero if absent)
       index1
       % Index of function name i in p2 (zero if absent)
       index2
       totalTime1
       totalTime2
       selfTime1
       selfTime2
       numCalls1
       numCalls2
       linesRun1
       linesRun2
       
       % These are the differences between the properties above
       dTotalTime
       dSelfTime
       dNumCalls
       dLinesRun
   end
   
   methods
       function obj = ProfileDiffResults(p1,p2)
            obj.data1 = p1;
            obj.data2 = p2;

            f1 = p1.FunctionTable;
            n1 = {f1.FunctionName};
            t1 = [f1.TotalTime];
            c1 = [f1.NumCalls];

            f2 = p2.FunctionTable;
            n2 = {f2.FunctionName};
            t2 = [f2.TotalTime];
            c2 = [f2.NumCalls];

            obj.functionNames = union(n1,n2);
            
            [~,obj.index1] = ismember(obj.functionNames,n1);
            [~,obj.index2] = ismember(obj.functionNames,n2);
            
            s = size(obj.index1);
            obj.totalTime1 = zeros(s);
            obj.totalTime2 = zeros(s);
            obj.selfTime1 = zeros(s);
            obj.selfTime2 = zeros(s);
            obj.numCalls1 = zeros(s);
            obj.numCalls2 = zeros(s);
            obj.linesRun1 = zeros(s);
            obj.linesRun2 = zeros(s);
            
            obj.dTotalTime = zeros(s);
            obj.dSelfTime = zeros(s);
            obj.dNumCalls = zeros(s);
            obj.dLinesRun = zeros(s);
       
           for k=1:numel(obj.functionNames)
                if obj.index1(k)
                    ind = obj.index1(k);
                    obj.totalTime1(k) = t1(ind);
                    obj.selfTime1(k) = obj.totalTime1(k) - sum([f1(ind).Children.TotalTime]);
                    obj.numCalls1(k) = c1(ind);
                    obj.linesRun1(k) = size(f1(ind).ExecutedLines,1); % number of rows
                end
                if obj.index2(k)
                    ind = obj.index2(k);
                    obj.totalTime2(k) = t2(ind);
                    obj.selfTime2(k) = obj.totalTime2(k) - sum([f2(ind).Children.TotalTime]);
                    obj.numCalls2(k) = c2(ind);
                    obj.linesRun2(k) = size(f2(ind).ExecutedLines,1); % number of rows
                end
                obj.dNumCalls(k) = obj.numCalls2(k) - obj.numCalls1(k);
                obj.dTotalTime(k) = obj.totalTime2(k) - obj.totalTime1(k);
                obj.dSelfTime(k) = obj.selfTime2(k) - obj.selfTime1(k);
                obj.dLinesRun(k) = obj.linesRun2(k) - obj.linesRun1(k);
           end
        end
        function report(obj,filename)
            fh = fopen(filename,'wt');
            closefile = onCleanup(@() fclose(fh));
            fprintf(fh,'Name, TotalTime1, SelfTime1, Calls1, LinesRun1, TotalTime2, SelfTime2, Calls2, LinesRun2, dTotalTime, dSelfTime, dCalls, dLinesRun\n');
            for k=1:numel(obj.functionNames)
                name = strrep(obj.functionNames{k},',','_');
                fprintf(fh,'%s,%f,%f,%d,%d,%f,%f,%d,%d,%f,%f,%d,%d\n',...
                    name,...
                    obj.totalTime1(k),obj.selfTime1(k),obj.numCalls1(k),obj.linesRun1(k),...
                    obj.totalTime2(k),obj.selfTime2(k),obj.numCalls2(k),obj.linesRun2(k),...
                    obj.dTotalTime(k),obj.dSelfTime(k),obj.dNumCalls(k),obj.dLinesRun(k));
            end
        end
   end
end