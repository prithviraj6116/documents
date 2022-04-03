function url = mcov_url_escape(url)

x = find(url==' ');

for i=length(x):-1:1
    url = [ url(1:x(i)-1) '%20' url(x(i)+1:end)];
end


