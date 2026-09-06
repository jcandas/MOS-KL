function plotDataErrorBars(Datas)

%close all
DataFields = ["CovTraining", "Machine", "Testing"];
Classes = ["B","A"];
nstds = 3;
colors = lines(length(Classes));

[C,D] = meshgrid(Classes, DataFields); ClassFields = [C(:), D(:)];

%% Create Figure
Units = "normalized";
figPos = [0.05, 0.1, 0.6, 0.95];
f = figure(Units = Units, OuterPosition = figPos);

for iDF = 1:length(DataFields)

%% Create Subplot
DataField = DataFields(iDF);
ax(iDF) = subplot(length(DataFields), 1, iDF); hold on
title(ax(iDF), DataField);

%% Create Subplot Data
for iC = 1:length(Classes)
C = Classes(iC);
m.(C) = mean(Datas.(C).(DataField),2); m.(C) = m.(C)(:)';
s = std(Datas.(C).(DataField),[],2); s = s(:)';
color = colors(iC,:);

for istd = nstds:-1:1
px = [1:length(m.(C)), length(m.(C)):-1:1 ];
py = [m.(C) + istd*s , fliplr(m.(C) - istd*s)];
patch(ax(iDF), px, py, color, FaceAlpha =  + 0.1*istd, LineStyle = "none");
end

end

for C = Classes
plot(m.(C), LineWidth = 2);
end
%% Add legend
isline = strcmp(arrayfun(@class, ax(iDF).Children, 'UniformOutput', false),...
    'matlab.graphics.chart.primitive.Line');
isline = isline(end:-1:1);
legstr = repmat("", size(isline));
legstr(isline) = Classes;
legend(legstr, Location = "eastoutside");


end

end
%==========================================================================
