function plotAUCs6
%% Includes GCM and SVM with PCA
close all

DSidx = [1:8];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitBox";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";
p.TrimB = false;

[DataSets, DataAliases] = GetDataSets();
DataSets = DataSets(DSidx);
DataAliases = DataAliases(DSidx);

Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];
Algos = ["MLS", "ACA" "Benchmark"];

switch p.TrimB, case true, nm = 11; case false, nm = 13; end
barArray = nan(length(DataSets), nm, 2, 2);
%McNemar = barArray; Wilcoxon = barArray;

LineColors = DefineLineColors;
[f, ax] = CreateFigure;

for iDS = 1:length(DataSets)
    barRow = barArray(iDS,:);
    DS = DataSets(iDS); p.DS = DS; 
    DA = DataAliases(iDS); p.DA = DA;
    p.Trunc = p.Truncs(iDS);
    
    X1 = GetFiles(p);
    
 for iAcc = 1:length(Accs), Acc = Accs(iAcc);   
    for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);

        if Algo == "Benchmark"
            X2 = X1(contains({X1.name}, "Benchmark"));
            load(fullfile(X2.folder, X2.name));
            if p.TrimB, [parameters, results] = TrimBenchmark(parameters, results); end
            len = length(parameters.misc.MachineList) - 1;
            barArray(iDS, end-len:end, 1, iAcc) = results.(Acc);
        
        else


            for iB = 1:length(Balances), Balance = Balances(iB);
                X2 = X1(contains({X1.name}, Algo) & ...
                        contains({X1.folder}, Balance));
                X3 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X2);
                
                switch Algo
                    case "MLS", iBar = 1:2;
                    case "ACA", iBar = 3:6;
                end
               
                [barArray(iDS,iBar,iB, iAcc), imax] = arrayfun(@(x) max(x.results.(Acc)), X3);
               % McNemar(iDS, iBar,iB,iAcc) = arrayfun(@(x,y) x.results.("McNemar_pvalue_" + Acc)(y), X3, imax);
               % Wilcoxon(iDS, iBar,iB,iAcc) = arrayfun(@(x,y) x.results.("Wilcoxon_pvalue_" + Acc)(y), X3, imax);
            end

        end
    end

   
end

end

barArrayOld = barArray;
barArray = squeeze(max(barArray,[],3,"omitnan"));
for iAcc = 1:length(Accs)
    Acc = Accs(iAcc);



axes(ax(iAcc));
b = bar(DataAliases , barArray(:,:,iAcc) ,...
    'FaceColor', 'flat', 'LineWidth', 0.2);
    for k = 1:length(b), for j = 1:size(b(k).CData,1)
        b(k).CData(j,:) = LineColors(k,:); 
    end, end


if iAcc == 2
    arrayfun(@(B) set(B,'Interpreter', 'latex'), b)
end

ax(iAcc).YLabel.String = Acc;
end

FixAxes(ax, p.TrimB);


plotPath = fullfile('..',p.Results,p.MOE, p.CrossVal, 'Graphs');
plotName = sprintf('Bar_Graph_5_Both_Regimes.pdf');
if ~isfolder(plotPath), mkdir(plotPath), end

exportgraphics(f, fullfile(plotPath, plotName));


 



end
%==========================================================================
function [DataSets, DataAliases] = GetDataSets()

a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];

DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;

DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
end

%==========================================================================
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

function [f ax] = CreateFigure


figHeight = 0.75;
figWidth = 0.85;
figLeft = 0.95 - figWidth;
figBottom = 0.95 - figHeight;
figPos = [figLeft, figBottom, figWidth, figHeight];

f = figure('units','normalized','outerposition',figPos);
nax = 2;
axHeights = [0.75, 0.25];
for i = 1:nax
    ax(i) = subplot(nax,1,i); 
    ax(i).Position(4) = 0.8*ax(i).Position(4);
    ax(i).Position(2) = axHeights(i) - 0.5*ax(i).Position(4);
    
end

end

%==========================================================================

function X = GetFiles(p)
folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.DS, p.HoldOut,'**', '*.mat');
X = dir(folderpath); 
mycontains = @(f,s) contains({X.(f)}, s); 

XBench = X(mycontains('name','Benchmark') &...
    mycontains('name',p.Normalized));
XBal = X(...
    ...mycontains('folder',p.Balance) &...
    mycontains('name',p.Nesting) & ...
    mycontains('name',p.Normalized) & ...
    mycontains('name',"Eigen-" + p.Trunc));

X = [XBench; XBal];
end
%==========================================================================

function FixAxes(ax, TrimB)

%% Global Axes Parameters
YTicks = 0.5:0.05:1; YTickLabels = num2cell(YTicks); YTickLabels(2:2:end) = {''};

MarkerSize = 12;
xFS = 12;
yFS = 17;
tFS = 20;
lFS = 12;

axNames = {'YLim', 'YGrid', 'fontsize', 'YTickMode', 'ytick','YTickLabels'};
axValues = {[0.5, 1], 'on', 11, 'manual', YTicks, YTickLabels};

for iax = 1:length(ax)
cellfun(@(x,y) set(ax(iax), x,y), axNames, axValues);

end
AxlabelArgs = {'Interpreter', 'latex', 'FontSize'};


axes(ax(1))
title('FINDER Methods vs. Benchmarks', AxlabelArgs{:}, tFS) 
legstr  = ["MLS-Lin", "MLS-RBF", "ACA-L-Lin", "ACA-L-RBF", "ACA-S-Lin", "ACA-S-RBF",...
           "SVM-Lin-PCA", "SVM-RBF-PCA", "SVM-Lin", "SVM-RBF",...
           "LogitBoost", "RUSBoost", "Bagging"];

if TrimB, legstr(contains(legstr, "PCA")) = []; end
ax(1).XTickLabel = {};
l = legend(legstr, 'Location', 'southoutside', ...
    'Orientation', 'Horizontal', AxlabelArgs{:}, lFS);
l.NumColumns = 5;

%% Center legend
legBottom = 0.5 - 0.5*l.Position(4);
legLeft = 0.5 - 0.5*l.Position(3);
l.Position([1 2]) = [legLeft, legBottom];
ylabel('AUC', AxlabelArgs{:}, yFS);

axes(ax(2))
ylabel('Accuracy', AxlabelArgs{:}, yFS);
ax(2).XLabel.FontSize = xFS;
ax(2).XAxis.TickLabelInterpreter = 'latex';

for i = 1:length(ax)
    currentYLim = ax(i).YLim;
    zoom(ax(i), 1.09);
    ax(i).YLim = currentYLim;
    ax(i).XAxis.TickLength = [0 0];
end

end

% %=================
% function nesting = GetNesting(X)
% 
% X(contains({X.name}, 'Benchmark')) = [];
% %svmonly = arrayfun(@(x) x.parameters.multilevel.svmonly, X);
% load(fullfile(X(1).folder, X(1).name));
% 
% 
% switch parameters.multilevel.nested
%     case 0, nesting = 'Unnested';
%     case 1, nesting = 'Inner-Nesting';
%     case 2, nesting = 'Outer-Nesting';
% end
% end
%=========================================================================
function [parameters, results] = TrimBenchmark(parameters, results)

if parameters.multilevel.svmonly ~= 1, return, end

isPCA = contains(parameters.misc.MachineList, "PCA");
parameters.misc.MachineList = parameters.misc.MachineList(~isPCA);
results.AUC = results.AUC(~isPCA);
results.accuracy = results.accuracy(~isPCA);

end
%==========================================================================