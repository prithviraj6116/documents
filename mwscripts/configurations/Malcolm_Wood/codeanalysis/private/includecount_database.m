function count = includecount_database(filename,refresh)
% count = includecount_database(filename)
%
% See also find_including_sources

persistent db;

if isempty(db)
    db = java.util.Hashtable;
end

count = db.get(filename);
if isempty(count) || (nargin>1 && refresh)
    count = find_including_sources(filename);
    db.put(filename,count);
end
end

