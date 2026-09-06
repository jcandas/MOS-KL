function plotSemisynthetic
close all

rF = 'results';
lFS = 12;
TrimB = false;

KeepBalanced = "Balanced";
KeepKernel = "RBF";


ClassSize = [600, 200, 10000];
ClassSize = sprintf('%d_TrainingA_%d_TrainingB_%d_Testing', ...
        ClassSize(1), ClassSize(2), ClassSize(3));

 
nesting = 'Inner-Nesting';

% transforms = arrayfun(@(x) replace( ...
%     sprintf("Noise_%0.g", x),...
%     '.', '_'), ...
%     5*10.^[-5,-4,-3]);
% 
% transforms = "id";
transforms = arrayfun(sprintf("Noise_%0.g", 0:0.1:0.5));
%transforms = ["id", transforms];

% transforms = arrayfun(@(x) sprintf("sin(%dx)",x) , [1,3,7] );

DSidx = [3:5, 11, 9, 8]; 

resultFolder = 'Manual_Hyperparameter_Selection';
Balances = ["Balanced"];
Accs = ["AUC", "accuracy"];
Algos = ["MLS", "ACA-S", "ACA-L", "Benchmark"];

DataSets = ["GCM", "newAD", ...
            arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]),...
            arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["EMCI_LMCI", "CN_EMCI", "CN_LMCI", "AD_LMCI", "AD_EMCI", "AD_CN"]) ];

DataAliases = ["GCM", "newAD", ...
                arrayfun(@(x) sprintf("ADNI (%s)", x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"]),...
               arrayfun(@(x) sprintf("CSF (%s)",x),...
               ["EMCI vs. LMCI", "CN vs. EMCI", "CN vs. LMCI", "AD vs. LMCI", "AD vs. EMCI", "AD vs. CN"])...
               ];

%% Iterate over ADNIs, Balances, and Accuracy measures

DataSets = DataSets(DSidx); DataAliases = DataAliases(DSidx);

for iTr = 1:length(transforms)
    transform = transforms(iTr);

for iDS = 1:length(DataSets)
    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    Best(iDS).DS = DS;
   
    
    f = figure('units','normalized','outerposition',[0.05 0.1 0.3 0.6]);

    

iplot = 0;

for iacc = 1:length(Accs)
    Acc = Accs(iacc);
    

plotData = cell(1,4);
for iBalance = 1:length(Balances)
        iplot = iplot + 1;
        ax = subplot(2,1,iplot); hold on,
        
        %if ismember(iplot, [2 4]), ax.Position(1) = 0.53; end
        Balance = Balances(iBalance);
        X2 = GetFiles(DS, Balance, rF, transform, ClassSize, KeepBalanced, KeepKernel);
        %if skipDS, continue, end
        assert(~isempty(X2), 'X2 is empty')

        legstr = [];
        for iAlgo = 1:length(Algos)
            Algo = Algos(iAlgo); X3 = X2(contains({X2.name}, Algo));
            

            assert(~isempty(X3), 'X3 is empty')
            [x1, y1, l, LineSpec] = GetPlotData(X3, Acc, Algo);
            legstr = [legstr, l];


        %% Set up axes
       
        PlotOnAxes(DA, Balance, x1, y1, iAlgo, ax, iplot, Acc, LineSpec);
        %Best(iDS) = UpdateBest(Best(iDS), x1, y1, l, Acc, Balance);
                               
      
        end

l = legend(legstr,...
    'Location', 'eastoutside',...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.9*[1 1 1]);

end


end

FixAxes(f);


plotPath = fullfile('..',rF,resultFolder,'Synthetic','Graphs', 'Noise');
if ~isfolder(plotPath), mkdir(plotPath), end
exportgraphics(f, fullfile(plotPath, ...
    sprintf('%s_%s_Synthetic.pdf', DS, transform ...
    )));
close(f)

end
end


end
%==========================================================================
%==========================================================================

function X= GetFiles(DS, Balance, rF, transform, ClassSize, KeepBalanced, KeepKernel)
    MOE = 'Manual_Hyperparameter_Selection';
    CrossVal = 'Synthetic';
    folderpath = fullfile('..', rF, MOE, CrossVal, DS, ClassSize, transform, '**', '*.mat');
    X = dir(folderpath); X(matches({X.name}, [".", ".."])) = [];

    switch KeepBalanced
        case "Balanced"
            idx = contains({X.folder}, "Balanced") | contains({X.name}, "Benchmark");
            X = X(idx);
        case "Unbalanced"
            X(contains({X.folder}, "Balanced")) = [];
    end

    Algos = ("MLS"| "ACA-S"|"ACA-L"|"Benchmark");
    switch KeepKernel
        case "linear"
            X(contains({X.name}, Algos) & contains({X.name}, "Radial")) = [];
        case "RBF"
            X(contains({X.name}, Algos) & contains({X.name}, "Linear")) = [];
    end

end

%=======================================================================

function [x1, y1, l, LineSpec] = GetPlotData(X3, Acc, Algo)
TrimB = false;
 %% Get Better performing Kernel
            X4 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X3);
            [~, iBestAcc] = max( arrayfun(@(x) max(x.results.(Acc)), X4));
            X4 = X4(iBestAcc);
            
            if TrimB, [X4.parameters, X4.results] = TrimBenchmark(X4.parameters, X4.results); end
            
            if Algo ~= "Benchmark"
            switch X4.parameters.svm.kernal
                case true, LineSpec1 = {'Marker', 's'};
                case false, LineSpec1 = {'Marker', 'o'};
            end
            else 
                LineSpec1 = {};
            end

            switch X4.parameters.multilevel.splitTraining
                case true, LineSpec2 = {'LineStyle', '--'};
                case false, LineSpec2 = {'LineStyle', '-'};
            end

            LineSpec = [LineSpec1, LineSpec2];


            l = "";
                  
            if ismember(Algo, ["MLS", "ACA-S", "ACA-L"])
                    x1 = X4.parameters.multilevel.Mres;
                    y1 = X4.results.(Acc);
                    l = Algo + l;
                    
            elseif Algo == "Benchmark"
                %x1 = minmax(X4.parameters.multilevel.Mres);
                x1 = get(gca, 'XLim');
                [y1, ix] = max(X4.results.(Acc));
                y1 = [1 1] * y1;
                l = X4.parameters.misc.MachineList(ix);
                %l = replace(l, '_', '-');
                l = replace(l, '_Linear', '-Lin');
                l = replace(l, '_Radial', '-RBF');
            end 
            %plotData{iAlgo} = [x1 ; y1];

            maxSpaces = 11;
            numSpaces = max(0, maxSpaces - length(l));
            padding = string(repmat(' ',[1 numSpaces]));
            l = l + padding;

end

function PlotOnAxes(DA, Balance, x1, y1, ...
                    iAlgo, ax, iplot,Acc, LineSpec)

minmax = @(x) [min(x) max(x)];
YTicks = 0.55:0.05:1;

MarkerSize = 8;
tFS = 15;
yFS = 15;
xFS = 15;

YTickLabels = num2cell(YTicks); YTickLabels(1:2:end) = {''};
%axNames = {'YLim', 'YGrid', 'YTickMode', 'ytick','YTickLabels', 'FontSize'};
%axValues = {minmax(YTicks), 'on', 'manual', YTicks, YTickLabels, yFS};
axNames = {'YGrid', 'FontSize'};
axValues = {'on', yFS};
LineArgs = {'LineWidth', 3, 'MarkerSize', MarkerSize, 'MarkerFaceColor', 'auto'};
LineArgs = [LineArgs, LineSpec];
%AxlabelArgs = {'Interpreter', 'latex', 'FontSize', FontSize};


capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

LineColors = [0.12, 0.21, 1; %MLS
            1, 0.04, 0.12; %ACA-S
            0.25, 0.25, 0.25; %ACA-L
            0.85, 0.67, 0.2]; %Benchmark;

        %title({DA, Balance}, 'Interpreter', 'latex', 'FontSize', tFS); 
        %title(Balance, 'Interpreter', 'latex', 'FontSize', tFS); 
      
         %Set up y-axes
        ylabel(capitalize(Acc), 'FontSize', yFS, 'Interpreter', 'latex');
        
        cellfun(@(x,y) set(ax,x,y), axNames, axValues);
        
        %Set up data & x-axes
        LineColor = LineColors(iAlgo,:);
        plot(ax,x1,y1,'Color', LineColor, LineArgs{:});
        
        if iplot == 1
            ax.XTickLabel = {};
        else 
            xlabel('$M_{res}$', 'Interpreter', 'latex', 'FontSize', xFS);
            ax.Position(2) = 0.18;
            
            if max(ax.XTick) > 1000
                Exponent = floor(log10(max(ax.XTick)));
                ax.XAxis.Exponent = Exponent;
            end

        end
        
        % if iplot == 1
        % annLeft = -0.05;
        % annWidth = 1;
        % annHeight = 0.05;
        % annBottom = 0.9-annHeight;
        % annPos = [annLeft, annBottom, annWidth, annHeight];
        % annotation('textbox',...
        %     'String', DA,...
        %     'FontSize', tFS + 2,...
        %     'VerticalAlignment', 'middle', ...
        %     'HorizontalAlignment', 'center',...
        %     'Interpreter', 'latex',...
        %     'Position',annPos,...
        %     'EdgeColor', 'none');
        % end
        %ax.XLim = minmax(X4.parameters.multilevel.Mres);

end

%==========================================================================
function FixAxes(f)
minmax = @(x) [min(x) max(x)];
ax = findall(f,'type','axes');
Positions = [0.2000    0.1700    0.4287    0.2729;
             0.2000    0.5238    0.4287    0.2729];
minHeight = 0.8*min(arrayfun(@(x) x.Position(4), ax));
minWidth = min(arrayfun(@(x) x.Position(3), ax));
for i = 1:length(ax)
    ichild = contains({ax(i).Children.DisplayName}, 'MLS');
    xl = minmax(ax(i).Children(ichild).XData);
    ax(i).XLim = xl;
     % p = ax(i).Position;
     % p([3 4]) = [minWidth minHeight]; 
     % p(2) = p(2) + (2-i)*0.9;
     % p(1) = 0.2;
     % ax(i).Position = p;
     GetWindow(ax(i));
     ax(i).Position = Positions(i,:);
     

    %% Add Asterisk to best Algos
    ch = ax(i).Children; 
    AlgoMaxes = arrayfun(@(x) max(x.YData), ch);
    AlgoMaxes = AlgoMaxes(end:-1:1);
    [AlgoMax, iAlgoMax] = max(AlgoMaxes);
    isAlgoMax = abs(AlgoMaxes - AlgoMax) < 0.00001;
    leg = legend(ax(i));
    str = string(leg.String);
    str(isAlgoMax) = str(isAlgoMax) + "$^*$";
    leg.String = str;
end
end
%==========================================================================
function GetWindow(ax)
Children = ax.Children;
isFINDER = contains({Children.DisplayName}, {'ACA', 'MLS'});
Children0 = Children(isFINDER);
Children1 = Children(~isFINDER);
YData = [Children.YData];
XData = [Children0.XData];
Baseline = unique(Children1.YData);
windowSize = max(YData) - min(YData);
windowSize = max(windowSize, 0.05);
windowSize = min(windowSize, 0.4);
windowSize = 0.05 * ceil(windowSize / 0.05);

window = [0, windowSize];
BestPoints = 0;
idealWindow = window;
keepShifting = true;
for i = 0:0.05:1-windowSize
    currentWindow = window + i;
    isInWindow = @(x) x >= currentWindow(1) & x <= currentWindow(2);
    if ~isInWindow(Baseline), continue, end

    
    indow = sum(isInWindow(YData));
    if indow >= BestPoints
        BestPoints = indow;
        idealWindow = currentWindow;
    end
end
window = idealWindow;

if windowSize <= 0.05
    spacing = 0.01;
    fspec = "%0.3f";
elseif windowSize <= 0.15
    spacing = 0.025;
    fspec = "%0.3f";
elseif windowSize > 0.15
    spacing = 0.05;
    fspec = "%0.2f";
end


YTicks =  window(1):spacing:window(2);
YTickLabels = arrayfun(@(x) sprintf("%0.2f",x), YTicks);
Y0 = arrayfun(@(x) sprintf(fspec,x), YTicks);
YTickLabels(endsWith(Y0, "5")) = "";

ax.YLim = window;
ax.YTick = YTicks;
ax.YTickLabels = YTickLabels;
ax.XLim = [min(XData), max(XData)];
ax.YAxis.FontSize = 11;
ax.YLabel.FontSize = 16;

end

%==========================================================================
function [parameters, results] = TrimBenchmark(parameters, results)

if parameters.multilevel.svmonly ~= 1, return, end

isPCA = contains(parameters.misc.MachineList, "PCA");
parameters.misc.MachineList = parameters.misc.MachineList(~isPCA);
results.AUC = results.AUC(~isPCA);
results.accuracy = results.accuracy(~isPCA);

end
%==========================================================================

% function WriteResultTable(Best, rF)
% TableFolder = fullfile('..', rF, 'Manual_Hyperparameter_Selection', 'Kfold','Graphs');
% TableName = 'AccuracyTable.tex';
% fileID = fopen(fullfile(TableFolder, TableName), "w+");
% 
% 
% end
