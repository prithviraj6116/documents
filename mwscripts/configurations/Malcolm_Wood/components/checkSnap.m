% Run using any MATLAB instance in a sandbox that contains the
% snap changeset

% Specifically:
% Sync matlab/config/components
% Sync config/clusters

c = ComponentAnalysis;
c.loadAllComponents;
p = CTBChecker(c,'Bslx'); % use Bslx.xml from this sandbox
p.writeHTML('problem_report.html');
!firefox problem_report.html &

% Depends on Bslx_ignore_list.tx being present in the sandbox.