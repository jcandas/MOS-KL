function plotErrorRateLineGraphs
close all

p.DSidx = [1:2];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

p = GetDataSets(p);

for iDS = 1:length(p.DS)
    
    p.ds = p.DS(iDS); 
    p.da = p.DA(iDS);
    p.Trunc = p.Truncs(iDS);
    [f, ax] = CreateFigure(p.Accs);
    fprintf('Processing %s \n', p.ds);

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
p.DS = DataSets;
p.DA = DataAliases;

% p.isGenetic = ismember(p.DS, p.DS(1:2));
% p.isPlasma = ismember(p.DS, p.DS(3:5));
% p.isCSF = ismember(p.DS, p.DS(6:8));

p.Sources = ["Genetic", "Plasma", "CSF"];
p.Genetic.DS = p.DS(1:2);
p.Plasma.DS = p.DS(3:5);
p.CSF.DS = p.DS(6:8);

%fields = ["DS", "DA", "is" + p.Sources, "Truncs"];
fields = ["DS", "DA", "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

p.Algos = ["MLS", "ACA-S", "ACA-L", "SVMs", "Boost/Bag"];
p.Finder = ["MLS", "ACA-S", "ACA-L"];
p.Accs = ["errorRate", "recall", "specificity", "precision"];

%% Get File IDs
Accs2 = strjoin(upper(extractBefore(p.Accs,4)), "-");
p.plotPath = fullfile("..",p.Results,p.MOE,p.CrossVal,"Graphs", Accs2);
if ~isfolder(p.plotPath), mkdir(p.plotPath), end

for Source = p.Sources
    p.(Source).texName = Source + "_" + p.Normalized + ".tex";
    p.(Source).texPath = fullfile(p.plotPath, p.(Source).texName);
    p.(Source).fID = fopen(p.(Source).texPath, "w+");
end


end
%==========================================================================
function [f, ax] = CreateFigure(Accs)

Accs = reshapeAccs(Accs);

[NRows, NCols] = size(Accs);

Units = 'centimeters';
LRMargin = 2.5; TWMargin = 4;
HWBFigs = 7; VWBFigs = 2; 

axWidth = 8; axHeight = 4.5; axProp = 0.6;
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

    folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
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
%==========================================================================
function p = GetPlotData(p)

 %% Get Better performing Kernel
if p.Acc == "errorRate", opt = @min; else opt = @max; end
iAcc = p.Accs == p.Acc;
iAlgo = p.Algos == p.Algo;


if ismember(p.Algo, p.Finder), idx = contains(p.paths, p.Algo);
else, idx = contains(p.paths, "Benchmark"); end

Paths = p.paths(idx);
X = cellfun(@load, Paths);

if ~ismember(p.Algo, p.Finder)
    switch p.Algo
    case "SVMs"
    isMachine = contains(X.parameters.misc.MachineList, "SVM");
    case "Boost/Bag"
    isMachine = ~contains(X.parameters.misc.MachineList, "SVM");
    end
    Machines = X.parameters.misc.MachineList(isMachine);
    [~,iX] = min(X.results.errorRate(isMachine));
    BestMachine = Machines(iX);
    iX = find(X.parameters.misc.MachineList == BestMachine);
else
    [~,iX] = min(arrayfun(@(x) min(x.results.errorRate), X));
end

if ismember(p.Algo, p.Finder)
    X = X(iX);
    p.x1 = X.parameters.multilevel.Mres;
    p.y1 = X.results.(p.Acc);
    p.l = p.Algo;

    switch X.parameters.svm.kernal
        case true, p.l = p.l+"-RBF";
        case false, p.l = p.l+"-Lin";
    end

    if X.parameters.multilevel.splitTraining, p.l = p.l + "*"; end
        
else
    minmax = @(x) [min(x), max(x)];
    p.x1 = minmax(X.parameters.multilevel.Mres);
    p.y1 = X.results.(p.Acc)(iX);
    p.y1 = [1 1] * p.y1;
    p.l = X.parameters.misc.MachineList(iX);
    p.l = replace(p.l, ["_Linear", "_Radial"], ["-Lin","-RBF"]);
end 

p.legstr = [p.legstr, p.l];      
end
%==========================================================================
function Acc = FixString(Acc)
if Acc == "AUC", return, end
indices = regexp(Acc, '[A-Z]'); 
if ~isempty(indices)
Acc = insertBefore(Acc, indices(end), " ");
end
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Acc = capitalize(Acc);
end
%==========================================================================
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
            0.5, 0.1, 0.8; %SVMs
            0.85, 0.67, 0.2]; %Boost/Bag;

ylabel(p.ax, FixString(p.Acc), 'FontSize', yFS, 'Interpreter', 'latex');
LineColor = LineColors(iAlgo,:);
plot(p.ax,p.x1,p.y1,'Color', LineColor, LineArgs{:});
cellfun(@(x,y) set(p.ax,x,y), axNames, axValues);

if length(p.ax.XTickLabel) >= 7, p.ax.XTickLabel(1:2:end) = {''}; end
        
       
end
%==========================================================================
function p = AddLegend(p)

lFS = 12;
Units = "centimeters";
p.leg = legend(p.ax, ...
    'String', p.legstr,...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.2*[1 1 1]);


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
    isBench = find(~contains({Lines.DisplayName}, ("ACA"|"MLS")));
    BenchLine = Lines(isBench(1));
    xlim(ax(iax), BenchLine.XData);
    
    if iax >= nax -1
        xlabel(ax(iax), '$M_{res}$', 'Interpreter', 'latex');
    end
    IDBest(ax(iax));
    GetWindow(ax(iax));

    ax(iax).FontSize = xFS;
    ax(iax).YLabel.FontSize = xFS + 4;
    ax(iax).XLabel.FontSize = xFS + 4;
    ax(iax).YLabel.Interpreter = "latex";
    ax(iax).TickLabelInterpreter = "latex";
    
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
    "String", "*Balanced Regime " + p.da,...
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

%if strcmp(ax.YLabel.String, 'Recall'), keyboard, end
IQR = quantile(YData, [0.25, 0.75]);
YIQR = YData(YData >= min(IQR) & YData <= max(IQR));
[~,mu,sigma] = zscore(YIQR);
Z = (YData - mu)/sigma;
YZ = YData(abs(Z) <= 3);
window = [min(YZ), max(YZ)];

% thr = 0.2;
% if isErrorRate
%     window = quantile(YData, [0,1-thr]);
% else
%     window = quantile(YData, [thr, 1]);
% end

isBench = ~contains({Children.DisplayName}, ["MLS", "ACA"]);
Bench = Children(isBench);
BenchVal = unique([Bench.YData]);
window(1) = min([window(1), BenchVal]);
window(2) = max([window(2), BenchVal]);


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
YTickMajor =  window(1):spacing:window(2);
YTickMinor = window(1):spacing:window(2);
YTickLabels = repmat("", size(YTickMinor));

%% Pare down Y Tick Labels
% first2 = round(scale*YTickMajor(1:2));
% istart = find(mod(first2,2) == 1);
% YTickMajor(istart:2:end) = [];
% YTickLabels(ismember(YTickMinor, YTickMajor)) = ...
%             arrayfun(@(x) sprintf(fspec,x), YTickMajor);
idelete = mod(round(scale*YTickMajor),2) == 1;
YTickMajor(idelete) = [];
YTickString = arrayfun(@(x) sprintf(fspec, x), YTickMajor);
YTickLabels(ismember(YTickMinor, YTickMajor)) = YTickString;
%YTickLabels = arrayfun(@(x) sprintf(fspec,x), YTicks);
%if length(YTickLabels) >= 5
%first2 = round(scale*str2double(YTickLabels(1:2)));
% if mod(first2(1),2) == 1
%     YTickLabels(1:2:end) = "";
% elseif mod(first2(2),2) == 1
%     YTickLabels(2:2:end) = "";
% end
%end

%% Eliminate Trailing zeros
endsWithZero = endsWith(YTickLabels,"0");
YTickLabels(endsWithZero) = extractBefore(YTickLabels(endsWithZero),5);

ax.YLim = window;
ax.YTick = YTickMinor;
ax.YGrid = "on";
ax.YTickLabels = YTickLabels;



end
%==========================================================================
function ExportGraph(p)

p.plotName = strjoin([p.ds, p.Normalized], "_");
p.graphPath = fullfile(p.plotPath, p.plotName) + ".pdf";
exportgraphics(gcf, p.graphPath);
close(gcf)


iSource = arrayfun(@(x) ismember(p.ds, p.(x).DS), p.Sources);
Source = p.Sources(iSource);

if isempty(Source), keyboard, end

edit(p.(Source).texPath);
fID = p.(Source).fID;
fprintf(fID, "\\begin{figure}[h!]\n\\centering\n");
fprintf(fID, "\\caption{\\textbf{%s}. A (*) represents the \\textit{balanced} regime.}\n", p.da);
fprintf(fID, "\\setlength{\\fboxrule}{0.1pt}\n"); % Thicker border lin
fprintf(fID, "\\setlength{\\fboxsep}{5pt}\n");
fprintf(fID, "\\fbox{\\includegraphics[width = \\globalLGWidth]\n");
fprintf(fID, "{Ch2/%s}}\n", p.plotName + ".pdf");
fprintf(fID, "\\label{%s_LineGraph}\n", p.da);
fprintf(fID, "\\end{figure}\n\n");

end
