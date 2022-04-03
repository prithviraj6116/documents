function print_stringtable
% Prints the contents of the Simulink string table, sorted by
% number of references
t = slInternal('stringtable');
counts = [t{:,2}];
[~,order] = sort(counts);
t(order,:)