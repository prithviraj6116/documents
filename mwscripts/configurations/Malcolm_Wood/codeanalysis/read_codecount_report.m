function [d,c] = read_codecount_report(filename)

dom = xmlread(filename);
e = dom.getElementsByTagName('snapshot');
n = double(e.getLength);
d = zeros(n,1);
c = zeros(n,1);
for i=1:n
    s = e.item(i-1);
    d(i) = datenum(char(s.getAttribute('date')),'yyyy:mm:dd');
    c(i) = str2double(char(s.getAttribute('executable')));
end
d = d- datenum('2006:01:01','yyyy:mm:dd');
[d,order] = sort(d);
d = d/365 + 2006;
c = c(order);
if nargout<2
    plot(d,c,'Marker','*');
    ylim(gca,[0 max(c)*1.05]);
    xlabel('Year');

% Create ylabel
ylabel('Executable Lines of Code');

end
end
