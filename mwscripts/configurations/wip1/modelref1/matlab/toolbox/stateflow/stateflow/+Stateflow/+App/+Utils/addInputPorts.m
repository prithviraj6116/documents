
function addInputPorts(sfxFileName, sfxChartName)
    sfxFullName = [sfxFileName '/' sfxChartName];
    chartId = sfprivate('block2chart',get_param(sfxFullName', 'handle'));
    chartH = sf('IdToHandle', chartId);
    inputData = chartH.find('-isa', 'Stateflow.Data', 'Scope', 'INPUT','Path',sfxFullName);
    outputData = chartH.find('-isa', 'Stateflow.Data', 'Scope', 'OUTPUT','Path',sfxFullName);
    inputEvent = chartH.find('-isa', 'Stateflow.Event', 'Scope', 'INPUT','Path',sfxFullName);
    chartPos = get_param(sfxFullName,'position');
    distanceFromChartX = 80;
    distanceFromChartY = 0;
    portWidth = 30;
    portHeigth = 14;
    offset = 20;
    for i  = 1:length(inputData)
        add_block('simulink/Sources/In1', [sfxFileName '/InPort' num2str(i)]);
        set_param([sfxFileName '/InPort' num2str(i)], 'Position', [chartPos(1)-distanceFromChartX chartPos(2)-distanceFromChartY+(i-1)*offset chartPos(1)-distanceFromChartX+portWidth chartPos(2)-distanceFromChartY+portHeigth+(i-1)*offset ]);
        add_line(sfxFileName, ['InPort' num2str(i) '/1'], [sfxChartName '/' num2str(i)]);
    end
    distanceFromChartX = 50;
    distanceFromChartY = 0;
    for i  = 1:length(outputData)
        add_block('simulink/Sinks/Out1', [sfxFileName '/OutPort' num2str(i)]);
        set_param([sfxFileName '/OutPort' num2str(i)], 'Position', [chartPos(3)+distanceFromChartX chartPos(4)-(chartPos(4)-chartPos(2))+distanceFromChartY+(i-1)*offset chartPos(3)+distanceFromChartX+portWidth chartPos(4)-(chartPos(4)-chartPos(2))+distanceFromChartY+portHeigth+(i-1)*offset ]);
        add_line(sfxFileName, [sfxChartName '/' num2str(i)], ['OutPort' num2str(i) '/1']);
    end
    for i = 1:length(inputEvent)
        eI = inputEvent(i);
        eI.Trigger = 'Either';
    end
    distanceFromChartX = 0;
    distanceFromChartY = -50;
    if ~isempty(inputEvent)
        add_block('simulink/Sources/In1', [sfxFileName '/InPortEvent' ]);
        set_param([sfxFileName '/InPortEvent'], 'Position', [chartPos(3)+distanceFromChartX chartPos(4)-(chartPos(4)-chartPos(2))+distanceFromChartY chartPos(3)+distanceFromChartX+portWidth chartPos(4)-(chartPos(4)-chartPos(2))+distanceFromChartY+portHeigth]);
        add_line(sfxFileName, 'InPortEvent/1', [sfxChartName '/trigger']);
    end
    return;
end