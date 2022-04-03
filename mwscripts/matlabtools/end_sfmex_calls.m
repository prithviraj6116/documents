function end_sfmex_calls(callNum)
%     disp(callNum);
    return;
    tabNum = start_sfmex_calls();
    if (callNum>0)
        disp([getTabs(tabNum) 'end ' num2str(callNum)]);
    end
end
function tabs = getTabs(numTabs)
    tabs = '';
    for i = 1:numTabs
        tabs = [tabs ' ']; %#ok<AGROW>
    end
end
