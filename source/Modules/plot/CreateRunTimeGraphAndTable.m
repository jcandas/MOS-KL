function CreateRunTimeGraphAndTable

CreateRunTimeGraph;
%CreateRunTimeTable;

end
%==========================================================================

function CreateRunTimeGraph
ep = 0.001;


close all
TablePath = fullfile('..','results2','Manual_Hyperparameter_Selection', 'Graphs');
load(fullfile(TablePath, 'RunTimeData.mat')); 
    Run_Times = Run_Times';
    [Run_Times, Headers] = RearrangeRun_Times(Run_Times, Headers);
    %DataAliases(3:end) = cellfun(@(x) extractBetween(x, '(', ')'), DataAliases(3:end));
breaks = [1 2 3 6 9];
[f, ax] = CreateFigure;

LineColors = DefineLineColors;

for i = 1:length(breaks)-1
    ibar = breaks(i):(breaks(i+1)-1);
b = bar(ax(i), DataAliases(ibar), Run_Times(:,ibar)  ,...
    'FaceColor', 'flat', 'LineWidth', 0.1);
    for k = 1:length(b)
        b(k).BarWidth = (1+ep)*b(k).BarWidth;
        for j = 1:size(b(k).CData,1)
        b(k).CData(j,:) = LineColors(k,:); 
    end, end
% Set the axes limits and labels for each subplot
end

FixAxes(ax);
axes(ax(1));
l = SetLegend(Headers);


plotPath = replace(TablePath, 'Tables', 'Graphs');
if ~isfolder(plotPath), mkdir(plotPath), end
exportgraphics(f, fullfile(plotPath, 'Run_Times_Graph.pdf'));
close(f)

end


%==========================================================================
function [Run_Times_Copy, Headers_Copy] = RearrangeRun_Times(Run_Times, Headers)
HeadersArray = [Headers{:}];
isPCA = contains(HeadersArray,"PCA");
%PCAs = Headers(isPCA);
isRawSVM = contains(HeadersArray, "SVM") & ~isPCA;
%SVMs = Headers(isRawSVM);
Run_Times_Copy = Run_Times;
Headers_Copy = Headers;
Run_Times_Copy(isRawSVM,:) = Run_Times(isPCA,:);
Run_Times_Copy(isPCA,:) = Run_Times(isRawSVM,:);
Headers_Copy(isRawSVM) = Headers(isPCA);
Headers_Copy(isPCA) = Headers(isRawSVM);
repfcns = {@(x) replace(x,"Linear", "Lin");
           @(x) replace(x,"Radial","RBF");
           @(x) replace(x, "_", "-")};

for i = 1:length(repfcns)
Headers_Copy = cellfun(repfcns{i}, Headers_Copy, 'UniformOutput', false);
end
%Headers_Copy = cellfun(repfcn2, Headers_Copy, 'UniformOutput', false);

end
%==========================================================================

function CreateRunTimeTable

TablePath = fullfile('..','results2','Manual_Hyperparameter_Selection', 'Kfold', 'Tables');
load(fullfile(TablePath, 'RunTimeData.mat')); %Run_Times = Run_Times';
filename = 'Run_Times_Table.tex';
fileID = fopen(fullfile(TablePath, filename), 'w');
methods = DefineMethods;

columnstr = repmat("",[1 length(Headers)+2]);
columnstr([3 8]) = "|";
columnstr(columnstr == "") = "C{2.1em}";
columnstr = strjoin(columnstr);
Headers = [Headers{:}];
Headers(end-2:end) = ["Logit Boost", "RUS Boost", "BAG ging"];

fprintf(fileID, ['\\begin{table} [h] \n'...
    '\\centering \n'...
    '\\begin{tabular}{|C{5em}| %s |} \n'...
    '\\hline \n'...
    '\\rowcolor{olive!40} \n'...
    '\\hline \n'], columnstr); %repmat(' C{2.5em}', size(Headers)));

fprintf(fileID, 'Datasets \n');
fprintf(fileID, '& %s ', Headers);
fprintf(fileID, '\\\\ \n\n');

%Breaks = [1,3,6];
isGenetic = ismember(DataSets, {'GCM', 'newAD'});
GDS = DataSets(isGenetic); GDA = DataAliases(isGenetic);
isADNI = ismember(DataSets, methods.data.ADNI_files);
ADS = DataSets(isADNI); ADA = DataAliases(isADNI);
isCSF = ismember(DataSets, methods.data.CSF_files);
CDS = DataSets(isCSF); CDA = DataAliases(isCSF);

Breaks = cumsum([0, length(GDS), length(ADS)]) + 1;
rowCounter = 0;
for iDS = 1:length(DataSets)

    
    if ismember(iDS, Breaks), rowCounter = 0; end
    rowCounter = rowCounter + 1;
    

    DS = DataSets(iDS);
    DA = DataAliases(iDS);

    %Print Header rows
    switch iDS
        case Breaks(1), PrintDataRowHeader(fileID, 'Genetic');  
        case Breaks(2), PrintDataRowHeader(fileID, 'Proteomic');
        case Breaks(3), PrintDataRowHeader(fileID, 'CSF');
    end

    if ismember(DS, ["GCM", "newAD"])
        rowColor = 'violet!30';
    elseif ismember(DS, ADS)
        rowColor = 'blue!20';
    elseif ismember(DS, CDS)
        rowColor = 'teal!40';
    end


    % if DS == "GCM" , j = 1;
    %     rowColor = 'violet!30';
    % elseif DS == "newAD", j = 2;
    %     rowColor = 'violet!30';
    % elseif ismember(DS, DataSets(3:5), j = 3;
    %     rowColor = 'blue!20';
    % elseif ismember(DS, DataSets(6:end)), j = 4;
    %     rowColor = 'teal!40';
    % end

    
    if mod(rowCounter, 2) == 1
        fprintf(fileID, '\\rowcolor{%s} \n', rowColor);
    end
    
    fprintf(fileID, '%s', DA);
    fprintf(fileID, ' & %0.2f', Run_Times(iDS, :));
    fprintf(fileID, '\\\\ \n');

end

fprintf(fileID, ['\\hline \n\n\n\n'...
'\\end{tabular} \n'...
'\\caption*{ } \n' ...
'\\label{Run_Times_Table} \n'...
'\\end{table} \n']);


fclose(fileID);

%%


end

%==========================================================================

function PrintDataRowHeader(fileID, tag)
    fprintf(fileID, ['\n \\hline \\hline ' ...
        '\\rowcolor{gray!30} ' ...
    '\\multicolumn{12}{|c|}{%s} \\\\ \n' ...
    '\\hline \\hline'], tag);
end

%==========================================================================

function LineColors = DefineLineColors

blue = [0.12, 0.21, 1]; %MLS
red = [1, 0.04, 0.12]; %ACA
gold = [0.85, 0.67, 0.2]; %Benchmark
violet = [0.5, 0.1, 0.8]; %PCA
white = [1, 1, 1];

t0 = [0.3;0.7];
t1 = [0.4;0.8];
t2 = [0.4;0.7;1];
%t2 = [0.2; 0.5; 1];

MLScolors = t1 .* blue;
ACAScolors = t1 .* red ;
ACALcolors = t0 .* white + (1-t0) .* red;
PCAcolors = t1 .* violet ; %+ (1-t1) .* violet;
SVMcolors = t0 .* white + (1-t0) .* violet; %t0 .* gold;
Othercolors = t2 .* gold; %t2 .* white + (1-t2) .* gold;

LineColors = [MLScolors;
    ACAScolors;
    ACALcolors;
    PCAcolors;
    SVMcolors;
    Othercolors];

end

%==========================================================================

function [f, ax] = CreateFigure

Units = [1 1 3 3]; 
Margins = 0.05; 
WidthBetweenPlots = 0.045;
PlotWidthUnit  = (1-(2*Margins + (length(Units)-1)*WidthBetweenPlots))/sum(Units);
PlotWidths = PlotWidthUnit * Units;
Positions = [0.1, 0.3, 0.58];

PlotLefts = [0, cumsum(PlotWidths(1:end-1))];
PlotLefts = [Margins + PlotLefts(1) ...
            (2:length(Units))*WidthBetweenPlots + PlotLefts(2:end)];


f = figure('units','normalized','outerposition',[0 0.1 0.85 0.50]);
%ax = axes;

FirstLeft = Margins;
for i = 1:length(Units), ax(i) = subplot(1,length(Units),i); end
axBottomUnit = 0.35 * ax(1).Position(3);
figBottom = 0.5;

for i = 1:length(Units)
    ax(i).Position = [FirstLeft,...
        figBottom,...
        PlotWidths(i),...
        0.95-figBottom];
    FirstLeft = FirstLeft + PlotWidths(i) + WidthBetweenPlots;
end

end

%==========================================================================

function FixAxes(ax)

%% Global Axes Parameters
%titles = ["Genetic", "Proteomic", "CSF"];
titles = ["GCM", "newAD", "Proteomic", "CSF"];
xFS = 14;
yFS = 16;
tFS = 17;
lFS = 10;

axes(ax(1))
ylabel('Run Times (s)', 'FontSize', yFS, 'Interpreter', 'latex')


for i = 1:length(ax)
     title(ax(i), titles(i), 'FontSize', tFS, 'Interpreter', 'latex');
     ax(i).XTickLabelRotation = 30;   
     %ax(i).XLabel.FontSize = xFS;
     set(ax(i), 'YGrid', 'on');
     ax(i).YAxis.FontSize = yFS - 3;
     ax(i).YLabel.FontSize = yFS;
     ax(i).XAxis.FontSize = xFS;
     ax(i).XAxis.TickLabelInterpreter = 'latex';
     currentYLim = ax(i).YLim;
     zoom(ax(i), 1.2);
     ax(i).YLim = currentYLim;
     %ax(i).CameraTarget = [1.5000 11.6746 0];
end



end
%==========================================================================
function l = SetLegend(Headers)

Margins = 0.13;
Width = 1 - 2*Margins;
LegHeight = 0.0759;
LegBottom = 0.18 - 0.5*LegHeight;
Position = [Margins, LegBottom, Width, LegHeight];
l = legend([Headers{:}], 'Location', 'southoutside', ...
    'Orientation', 'Horizontal', 'Interpreter', 'latex', ...
    'FontSize', 13, 'NumColumns', 7, 'Position',  Position);

end