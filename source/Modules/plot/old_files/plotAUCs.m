function plotAUCs
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

p = GetDataSets(p);

for iDS = 1:length(p.DataSets)
    
    p.DS = p.DataSets(iDS); 
    p.DA = p.DataAliases(iDS);
    p.Trunc = p.Truncs(iDS);
    [f, ax] = CreateFigure(p.Accs);
    fprintf('Processing %s \n', p.DS);

   p.iBest = nan(size(p.Algos));
for iacc = 1:length(p.Accs)
    p.Acc = p.Accs(iacc);
    p.ax = ax(iacc);
    
        p = GetFiles(p);
        p.legstr = [];
        
        for iAlgo = 1:length(p.Algos)

            p.Algo = p.Algos(iAlgo); 
            p = GetPlotData(p);
            PlotOnAxes(p);                              
        end

p = AddLegend(p);
end

FixAxes(ax);
%AddPostScript(p);
ExportGraph(p);
end

end
%==========================================================================
function Accs = reshapeAccs(Accs)
if mod(length(Accs),2) == 1
    Accs = [Accs, ""];
end
Accs = reshape(Accs, 2,[])';
end
%==========================================================================
function p = GetDataSets(p)
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
p.DataSets = DataSets;
p.DataAliases = DataAliases;
for field = ["DataSets", "DataAliases", "Truncs"]
    p.(field) = p.(field)(p.DSidx);
end
p.Algos = ["MLS", "ACA-S", "ACA-L", "Benchmark"];
p.Accs = ["errorRate", "recall", "specificity", "precision"];


end
%==========================================================================
function [f, ax] = CreateFigure(Accs)

Accs = reshapeAccs(Accs);

[NRows, NCols] = size(Accs);

Units = 'centimeters';
LRMargin = 2.5; TWMargin = 4;
HWBFigs = 7; VWBFigs = 1; 

axWidth = 8; axHeight = 4; axProp = 0.6;
figWidth = 4*LRMargin + NCols*axWidth + (NCols-1)*HWBFigs;
figHeight = 2*TWMargin + NRows*axHeight + (NRows-1)*VWBFigs;

f = figure('Units', Units, "Outerposition", [0,0,figWidth,figHeight]);

nax = sum(Accs ~= "", 'all');

for iax = 1:nax, ax(iax) = subplot(NRows, NCols, iax); hold on; end

for iax = 1:nax
    if iax == 1
        axLeft = LRMargin;
        axBottom = figHeight - axHeight - TWMargin;
    elseif iax > 1 && iax <= NCols
        axLeft = ax(iax-1).Position(1) + axWidth + HWBFigs; 
        axBottom = ax(iax-1).Position(2);        
    elseif iax > 1 && mod(iax, NCols) == 1
        axLeft = LRMargin;
        axBottom = ax(iax - NCols).Position(2) - axHeight - VWBFigs;
    else 
        axLeft = ax(iax-1).Position(1) + axWidth + HWBFigs;
        axBottom = ax(iax - NCols).Position(2) - axHeight - VWBFigs;
    end
    
    axPos = [axLeft, axBottom, axWidth, axHeight];
    ax(iax).Units = Units; ax(iax).Position = axPos;
end


end
%==========================================================================
function p = GetFiles(p)

    folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.DS, p.HoldOut,'**', '*.mat');
    X = dir(folderpath); 
    X = fullfile({X.folder}, {X.name});
   
    XBench = X(contains(X,'Benchmark') &...
               contains(X,p.Normalized));
    XBal = X(...
             contains(X,p.Nesting) & ...
             contains(X,p.Normalized) & ...
             contains(X,"Eigen-" + p.Trunc));

    p.paths = vertcat(XBench, XBal{:});
  

    assert(~isempty(p.paths), 'No paths found')
end

%=======================================================================
function p = GetPlotData(p)

 %% Get Better performing Kernel
if p.Acc == "errorRate", opt = @min; else opt = @max; end
iAcc = p.Accs == p.Acc;
iAlgo = p.Algos == p.Algo;

Paths = p.paths(contains(p.paths,p.Algo));
X = cellfun(@load, Paths);

if p.Algo == "Benchmark"
    [~,iX] = min(X.results.errorRate);
else
    [~,iX] = min(arrayfun(@(x) min(x.results.errorRate), X));
end

if ismember(p.Algo, ["MLS", "ACA-S", "ACA-L"])
    X = X(iX);
    p.x1 = X.parameters.multilevel.Mres;
    p.y1 = X.results.(p.Acc);
    p.l = p.Algo;

    switch X.parameters.svm.kernal
        case true, p.l = p.l+"-RBF";
        case false, p.l = p.l+"-Lin";
    end

    if X.parameters.multilevel.splitTraining, p.l = p.l + "*"; end
        
elseif p.Algo == "Benchmark"
    %x1 = get(gca, 'XLim');
    minmax = @(x) [min(x), max(x)];
    p.x1 = minmax(X.parameters.multilevel.Mres);
    %[p.y1, ix] = opt(X.results.(Acc));
    p.y1 = X.results.(p.Acc)(iX);
    p.y1 = [1 1] * p.y1;
    %p.l = X.parameters.misc.MachineList(ix);
    p.l = X.parameters.misc.MachineList(iX);
    p.l = replace(p.l, ["_Linear", "_Radial"], ["-Lin","-RBF"]);
end 

p.legstr = [p.legstr, p.l];      
end
%==========================================================================
function Acc = FixString(Acc)
if Acc == "AUC", return, end;
indices = regexp(Acc, '[A-Z]'); 
if ~isempty(indices)
Acc = insertBefore(Acc, indices(end), " ");
end
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Acc = capitalize(Acc);
end
%==========================================================================
%function PlotOnAxes(x1,y1,ax,iAlgo,Acc,DA)
function PlotOnAxes(p)

iAlgo = p.Algos == p.Algo;
YTicks = 0.5:0.1:1; 
if p.Acc == "errorRate", YTicks = sort(1 - YTicks); end
minmax = @(x) [min(x) max(x)];

MarkerSize = 8;
tFS = 15;
yFS = 15;
xFS = 15;

YTickLabels = num2cell(YTicks); YTickLabels(1:2:end) = {''};
axNames = {'YLim', 'YGrid', 'YTickMode', 'ytick','YTickLabels', 'FontSize'};
%axNames = {'YGrid', 'YTickMode','FontSize'};
axValues = {minmax(YTicks), 'on', 'manual', YTicks, YTickLabels, yFS};
%axValues = {'on','manual',yFS};
LineArgs = {'LineWidth', 3, 'Marker', 's', 'MarkerSize', MarkerSize, 'MarkerFaceColor', 'auto'};


LineColors = [0.12, 0.21, 1; %MLS
            1, 0.04, 0.12; %ACA-S
            0.25, 0.25, 0.25; %ACA-L
            0.85, 0.67, 0.2]; %Benchmark;

        % if ismember(iplot, [1 3])
        % 
        % end

ylabel(p.ax, FixString(p.Acc), 'FontSize', yFS, 'Interpreter', 'latex');
LineColor = LineColors(iAlgo,:);
plot(p.ax,p.x1,p.y1,'Color', LineColor, LineArgs{:});
cellfun(@(x,y) set(p.ax,x,y), axNames, axValues);

if length(p.ax.XTickLabel) >= 7, p.ax.XTickLabel(1:2:end) = {''}; end
        
       
end
%==========================================================================
%function l = AddLegend(ax, str)
function p = AddLegend(p)

lFS = 12;
Units = "centimeters";
p.leg = legend(p.ax, ...
    'String', p.legstr,...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.9*[1 1 1]);


p.ax.Units = Units; p.leg.Units = Units;
axPos = p.ax.Position; legPos = p.leg.Position;
legPos(2) = axPos(4)+axPos(2) - legPos(4);
legPos(1) = axPos(1) + axPos(3) + 0.5;
p.leg.Position = legPos;
p.ax.Position = axPos;

end
%==========================================================================
function FixAxes(ax)

xFS = 15;
nax = length(ax);
for iax = 1:nax
    Lines = findall(ax(iax),'type', 'Line');
    isBench = ~contains({Lines.DisplayName}, ("ACA"|"MLS"));
    BenchLine = Lines(isBench);
    xlim(ax(iax), BenchLine.XData);
    
    if iax >= nax -1
        xlabel(ax(iax), '$M_{res}$', 'Interpreter', 'latex', 'FontSize', xFS);
    end
    IDBest(ax(iax));
    GetWindow(ax(iax));
    
end


end
%==========================================================================
function IDBest(ax)

Acc = string(ax.YLabel.String);

Children = ax.Children;
Y1 = arrayfun(@(x) x.YData, Children, 'UniformOutput', false);
X1 = arrayfun(@(x) x.XData, Children, 'UniformOutput', false);

isErrorRate = Acc == "Error Rate";
if isErrorRate 
   opt = @min; optstr = "Min";
else, opt = @max; optstr = "Max";
end

[~,i1] = cellfun(opt, Y1, 'UniformOutput', false);
fun = @(y,x) y(x);
Y2 = cellfun(fun, Y1, i1); X2 = cellfun(fun, X1, i1);

[~,i2] = opt(Y2); 
Y3 = Y2(i2); X3 = X2(i2);


FINDER = ("MLS"|"ACA-L"|"ACA-S");
Algo = extract(string(Children(i2).DisplayName), FINDER);
if isempty(Algo), Algo = string(Children(i2).DisplayName); end

str = [Algo; sprintf("%s = %0.3f", optstr, Y3)];

if contains(Algo, FINDER)
    str = [str; sprintf("$M_{res} = %d$ ", X3)];
end

l = legend(ax);
annLeft = l.Position(1);
annBottom = ax.Position(2);
annWidth = l.Position(3);
annHeight = ax.Position(4) - l.Position(4) - 0.02;
annPos = [annLeft, annBottom, annWidth, annHeight];

ann = annotation("textbox",...
            "Units", l.Units,...
           "String", str,...
            "FontSize", l.FontSize,...
            "VerticalAlignment", 'middle', ...
            "HorizontalAlignment", 'left',...
            "Interpreter", 'latex',...
            "Position",annPos,...
            "EdgeColor", l.EdgeColor,...
            "BackgroundColor", l.Color);

end
%==========================================================================
function AddPostScript(p)
f = gcf
Units = "normalized";
psFS = 16;
f.Units = Units;
ax = findall(f, 'type', 'axes');
arrayfun(@(a) set(a,"Units", Units), ax);
Bottoms = arrayfun(@(x) x.Position(2), ax);
annLeft = 0;
annBottom = 0; %min(Bottoms);
annHeight = 0.8*min(Bottoms); %0.01;
annWidth = 1; %f.Position(3);
annPos = [annLeft, annBottom, annWidth, annHeight];

ann = annotation(f, "textbox", annPos,...
    "String", "*Balanced Regime " + p.DA,...
    "FontSize", psFS,...
    "VerticalAlignment", "top",...
    "HorizontalAlignment", "center",...
    "Interpreter", "latex",...
    ..."Position", annPos,...
    "EdgeColor", "none",...
    "BackgroundColor", "none");
end
%==========================================================================
function GetWindow(ax)


%% Get y-axis data
minWindowSize = 0.05;
Children = ax.Children;
YData = [Children.YData];
isErrorRate = strcmp(ax.YLabel.String, 'Error Rate');
thr = 0.2;
if isErrorRate
    window = quantile(YData, [0,1-thr]);
else
    window = quantile(YData, [thr, 1]);
end

isBench = ~contains({Children.DisplayName}, ["MLS", "ACA"]);
Bench = Children(isBench);
BenchVal = Bench.YData(1);
window(1) = min(window(1), BenchVal);
window(2) = max(window(2), BenchVal);


%% Construct a sensible scale
windowSize = window(2) - window(1);
edges = [0, 0.05, 0.15, 0.3, 1];
spacings = [0.01, 0.025, 0.05, 0.2];
fspecs = repmat("%0.2f", size(spacings));
fspecs(spacings == 0.025) = "%0.3f";
idx = discretize(windowSize, edges);
spacing = spacings(idx); fspec = fspecs(idx);
scale = 10^str2double(extractBetween(fspec, ".", "f"));

window(1) = max(spacing * floor(window(1) / spacing),0);
window(2) = min(spacing * ceil(window(2) / spacing),1);


%% Compensate if window is too small
windowSize = window(2) - window(1);
if windowSize < minWindowSize
    totalPadding = minWindowSize - windowSize;
    switch isErrorRate
        case false
        t1 = 1 - window(2);
        t2 = spacing*floor(totalPadding/(2*spacing));
        upperPadding = min(t1, t2);
        lowerPadding = totalPadding - upperPadding;

        case true
        t1 = window(1);
        t2 = spacing*floor(totalPadding/(2*spacing));
        lowerPadding = min(t1, t2);
        upperPadding = totalPadding - lowerPadding;
    end
    window = window + [-lowerPadding, upperPadding];
   
end

%% Set YTicks
YTicks =  window(1):spacing:window(2);

%% Pare down Y Tick Labels
YTickLabels = arrayfun(@(x) sprintf(fspec,x), YTicks);
%if length(YTickLabels) >= 5
first2 = round(scale*str2double(YTickLabels(1:2)));
if mod(first2(1),2) == 1
    YTickLabels(1:2:end) = "";
elseif mod(first2(2),2) == 1
    YTickLabels(2:2:end) = "";
end
%end

%% Eliminate Trailing zeros
endsWithZero = endsWith(YTickLabels,"0");
YTickLabels(endsWithZero) = extractBefore(YTickLabels(endsWithZero),5);

ax.YLim = window;
ax.YTick = YTicks;
ax.YGrid = "on";
ax.YTickLabels = YTickLabels;
ax.YAxis.FontSize = 11;
ax.YLabel.FontSize = 16;


end
%==========================================================================
function ExportGraph(p)


Accs2 = strjoin(upper(extractBefore(p.Accs,4)), "-");
plotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,"Graphs", Accs2);
plotName = strjoin([p.DS, p.Normalized], "_");
if ~isfolder(plotPath), mkdir(plotPath), end
graphPath = fullfile(plotPath, plotName) + ".pdf";
exportgraphics(gcf, graphPath);
close(gcf)
fclose all;

fID = fopen(fullfile(plotPath, plotName) + ".txt", "w+");
fprintf(fID, "\\begin{figure}[h]\n\\centering\n");
fprintf(fID, "\\caption{\\textbf{%s}}\n", p.DA);
fprintf(fID, "\\includegraphics[\\height = \\globalLGHeight, width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2\\%s}\n", plotName + ".pdf");
fprintf(fID, "\\label{%s_LineGraph}\n", p.DA);
fprintf(fID, "\\end{figure}");

end
