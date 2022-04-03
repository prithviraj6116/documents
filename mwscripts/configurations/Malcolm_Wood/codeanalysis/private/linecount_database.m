function count = linecount_database(filename,refresh)
% count = linecount_database(filename)
%
% See also line_count

persistent db;

if isempty(db)
    db = java.util.Hashtable;
end

count = db.get(filename);
if isempty(count) || isnan(count) || (nargin>1 && refresh)
    count = linecount(filename);
    db.put(filename,count);
end
end

