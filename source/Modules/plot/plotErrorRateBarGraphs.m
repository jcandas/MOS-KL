function plotErrorRateBarGraphs
%% Includes GCM and SVM with PCA
close all

p.DSidx = [1:8];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";
p.TrimB = false;
p.FontSize = "tiny";

p = GetDataSets(p);
p = DefineLineColors(p);
p = CreateFigure(p);

for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS); 
    p.Trunc = p.Truncs(iDS);  
    fprintf("Processing %s\n", p.ds);
for iAlgo = 1:size(p.Algos,1)
    p.Algo = p.Algos(iAlgo,:);
    p = GetFiles(p);
    p = FillArray(p);  
end
end

PlotBars(p);
AddLegend(p);
ExportFig(p);

% p = GetfID(p);
% PrintHeader(p);
% PrintBody(p);
% PrintFooter(p);

end
%==========================================================================
function p = GetDataSets(p)

%% Data Sets and Data Aliases
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
p.DS = DataSets; p.DA = DataAliases;
fields = ["DS", "DA",  "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

%% Algorithms
F = ["MLS", "ACA-S", "ACA-L"]; K = ["Linear", "Radial"];
[F,K] = meshgrid(F,K); FK = [F(:), K(:)]; 
[S,K2,P] = ndgrid("SVM_", ["Linear", "Radial"], ["", "-PCA"]);

p.Algos = [FK ; "Benchmark" ""];
p.SVMs = S(:) + K2(:) + P(:);
p.Boosts = ["LogitBoost"; "RUSBoost"; "Bag"];
p.Benchmarks = [p.SVMs ; p.Boosts];
p.Classifiers = [FK ; p.Benchmarks , repmat("", size(p.Benchmarks))];

%% Accuracy Measures
p.Accs = ["errorRate", "recall", "specificity", "precision"];

%% Legend String
p.FINDER = F(:) + "-" + K(:);
p.LegendString = replace([p.FINDER; p.Benchmarks], ["Linear", "Radial"], ["Lin", "RBF"]);


%% Bar Graph Array
p.BarArray = nan(length(p.DS), length(p.LegendString), length(p.Accs));

p.Sources = ["Genetic", "Plasma", "CSF"];
p.Genetic.DS = p.DS(ismember(p.DS, DataSets(1:2)));
p.Plasma.DS = p.DS(ismember(p.DS, DataSets(3:5)));
p.CSF.DS = p.DS(ismember(p.DS, DataSets(6:8)));
end

%==========================================================================
%==========================================================================
function p = DefineLineColors(p)

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

p.LineColors = [MLScolors;
    ACAScolors;
    ACALcolors;
    PCAcolors;
    SVMcolors;
    Othercolors];

end

%==========================================================================
function p = CreateFigure(p)

p.Units = "normalized";

figHeight = 0.9;
figWidth = 0.5;
figLeft = 0;
figBottom = 0;
figPos = [figLeft, figBottom, figWidth, figHeight];

LRMargins = 0.1;
TopMargin = 0.02;
BottomMargin = 0.4;
AxVSpacing = 0.05;

nax = length(p.Accs);
axWidth = 1 - 2*LRMargins;
axHeight = (figHeight - TopMargin - BottomMargin) / nax;

f = figure('units',p.Units,'outerposition',figPos);

for i = 1:nax
ax(i) = subplot(nax,1,i);     
end

for i = 1:nax
axLeft = LRMargins;
axBottom = figHeight - TopMargin - i*axHeight - (i-1)*AxVSpacing;
axPos = [axLeft axBottom axWidth axHeight];
ax(i).Position = axPos;
hold on 
end

p.f = f;
p.ax = ax;

end

%==========================================================================
function p = GetFiles(p)
folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X = dir(folderpath); 
Paths = fullfile({X.folder}, {X.name});

idx = contains(Paths, p.Algo(1)) & ... 
      contains(Paths, p.Algo(2)) & ...
      contains(Paths, p.Normalized);

if p.Algo(1) ~= "Benchmark"
    idx = idx & contains(Paths, "Eigen-" + p.Trunc);
end
Paths = Paths(idx);
if isempty(Paths), keyboard, end
X = cellfun(@load, Paths);
if p.Algo(1) ~= "Benchmark"
m = arrayfun(@(x) min(x.results.errorRate), X);
[~,im] = min(m);
else
    im = 1;
end
p.Path = Paths{im};

if iscell(p.Path), keyboard, end

end
%==========================================================================
function p = FillArray(p)
for iAcc = 1:length(p.Accs)
    p.Acc = p.Accs(iAcc);

    if p.Acc == "errorRate", opt = @min;
    else, opt = @max; end

    load(p.Path);
    iDS = p.DS == p.ds;
    
    switch p.Algo(1) == "Benchmark"
        case true
            iM = arrayfun(@(i) find(p.Classifiers(:,1) == i), parameters.misc.MachineList);
            p.BarArray(iDS, iM, iAcc) = results.(p.Acc);
        case false
            [~,iL] = min(results.errorRate);
            iM = all(p.Classifiers == p.Algo, 2);
            p.BarArray(iDS, iM, iAcc) = results.(p.Acc)(iL);
    end

    
end
end
%==========================================================================
function PlotBars(p)
for iAcc = 1:length(p.Accs)
    p.Acc = p.Accs(iAcc);

    b = bar(p.ax(iAcc), p.BarArray(:,:,iAcc) ,...
        'FaceColor', 'flat', 'LineWidth', 0.2);

    for k = 1:length(b), for j = 1:size(b(k).CData,1)
            b(k).CData(j,:) = p.LineColors(k,:); 
    end, end

    arrayfun(@(B) set(B,'Interpreter', 'latex'), b)

    FixAxes(p)
end
end
%==========================================================================
function FixAxes(p)

%% Global Axes Parameters
iAcc = find(p.Accs == p.Acc);
ax = p.ax(iAcc);
if p.Acc == "errorRate"
    YTicks = 0:0.1:0.5;
    YTickLoc = 0:0.2:0.5;
else
    YTicks = 0.5:0.1:1; 
    YTickLoc = 0.6:0.2:1;
end
YTickLabels = repmat("", size(YTicks)); 
YTickLabels(ismember(YTicks,YTickLoc)) = string(YTickLoc);
yl = [min(YTicks) max(YTicks)];

MarkerSize = 12;
xFS = 12;
yFS = 15;
tFS = 20;

axNames = {'YLim', 'YTick', 'YTickLabels', 'YGrid', 'fontsize', 'YTickMode', 'TickLength'};
axValues = {yl, YTicks, YTickLabels, 'on', 11, 'manual', [0.005, 0.005]};

cellfun(@(x,y) set(ax, x,y), axNames, axValues);

AxlabelArgs = {'Interpreter', 'latex', 'FontSize'};
if iAcc == 1
title(ax, 'FINDER Methods vs. Benchmarks', AxlabelArgs{:}, tFS) 
end

capitalize = @(s) upper(extractBefore(s,2)) + extractAfter(s,1);
Acc = capitalize(p.Acc);
Acc = replace(Acc, "ErrorRate", "Error Rate");
ylabel(ax, Acc, AxlabelArgs{:}, yFS);

ax.Box = "off";
ax.TickLabelInterpreter = "latex";
ax.XTickLabels = "";
if iAcc == length(p.Accs)
ax.XTickLabels = p.DA;
ax.XTickLabelRotation = 30;
ax.XLabel.FontSize = xFS;
end

end
%==========================================================================
function AddLegend(p)
lFS = 10;

p.LegendString = replace(p.LegendString, "_", "-");

l = legend(p.ax(end), p.LegendString,...
    "Location", "southoutside", ...
    "Orientation", "Horizontal", ...
    "Interpreter", "latex",...
    "FontSize", lFS,...
    "NumColumns", ceil(length(p.LegendString)/3));

l.Position(1) = 0.5*(1 - l.Position(3));
l.Position(2) = p.ax(end).Position(2) - l.Position(4) - 0.25;
end
%==========================================================================
function ExportFig(p)
p.AccStr = strjoin(upper(extractBefore(p.Accs,4)), "-");
plotPath = fullfile('..',p.Results,p.MOE, p.CrossVal, "Graphs", p.AccStr);
plotName = sprintf('Performance_Bar_Graph.pdf');
if ~isfolder(plotPath), mkdir(plotPath), end
exportgraphics(p.f, fullfile(plotPath, plotName));
close(p.f)
end
%==========================================================================
function p = GetfID(p)
p.TableFolder = fullfile("..",p.Results,p.MOE, p.CrossVal, "Tables", p.AccStr);
p.TableName = "Performance_Table";
if ~isfolder(p.TableFolder), mkdir(p.TableFolder), end
path = fullfile(p.TableFolder, p.TableName + ".tex");
p.fID = fopen(path, "w+");
edit(path);
end
%==========================================================================
function PrintHeader(p)

%% Print Table "preamble"
fprintf(p.fID, "\\begin{%s}\n", p.FontSize);
fprintf(p.fID, '\\begin{longtable}[c]\n');

nDS = arrayfun(@(f) length(p.(f).DS), p.Sources);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.3em}",[1 x])), [1 nDS]);
columnstr(1) = "C{4.8em}";
columnstr = "|" + strjoin(columnstr,"||") + "|";

fprintf(p.fID, '{%s}\n',columnstr);
fprintf(p.fID, '\\hline \n \\rowcolor{olive!40}\n Metric');

cellchars = repmat("|c||", size(p.Sources));
cellchars(end) = "|c|";
for i = 1:length(p.Sources)
    fprintf(p.fID, " & \\multicolumn{%d}{%s}{%s}",...
        nDS(i), cellchars(i), p.Sources(i));
end
fprintf(p.fID, '\\\\\n \\hline \n\n \\rowcolor{gray!20} \n\n');

%% print actual datasets
pattern = ("ADNI "| "CSF "| "("| ")");
DataAliases = arrayfun(@(x) replace(x,pattern, ''), p.DA);

for i = 1:length(p.Sources)
Source = p.Sources(i);
DA = DataAliases(ismember(p.DS, p.(Source).DS));
fprintf(p.fID, "& %s ", DA);
end
fprintf(p.fID, " \\\\ \n \\hline");

end

%==========================================================================
function PrintBody(p)

%% Print Header
for iAcc = 1:length(p.Accs)

end

end