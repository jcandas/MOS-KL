function plotAUCs
close all

DSidx = [2];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

lFS = 12;
TrimB = false;

[DataSets, DataAliases] = GetDataSets();
p.Truncs = p.Truncs(DSidx);
DataSets = DataSets(DSidx); 
DataAliases = DataAliases(DSidx);

%Balances = ["Balanced", "Unbalanced"];
Algos = ["MLS", "ACA-S", "ACA-L", "Benchmark"];
Accs = ["errorRate", "recall", "specificity", "accuracy", "precision", "AUC", "F1Score"];
Accs = 



%% Iterate over ADNIs, Balances, and Accuracy measures

fileIDs = OpenFileIDs(p);
Best = MakeBestStruct(DataSets, Accs);
Best = arrayfun(@(b,d) setfield(b, 'DS', d), Best, DataSets);
Best = arrayfun(@(b) setfield(b, 'nesting', p.Nesting), Best);

for iDS = 1:length(DataSets)
    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    p.Trunc = p.Truncs(iDS);
    Best(iDS).DS = DS;
   
    f = figure('units','normalized','outerposition',[0.05 0.1 0.8 0.2]);

for iacc = 1:length(Accs)
    Acc = Accs(iacc);
    


for iBalance = 1:length(Balances)
        iplot = iplot + 1;
        ax = subplot(2,2,iplot); hold on,
        
       
        Balance = Balances(iBalance);
        p.Balance = Balance;
        X2 = GetFiles(DS, p);
        %if skipDS, continue, end
        assert(~isempty(X2), 'X2 is empty')

        legstr = [];
        for iAlgo = 1:length(Algos)
            Algo = Algos(iAlgo); X3 = X2(contains({X2.name}, Algo));
            

            assert(~isempty(X3), 'X3 is empty')
            [x1, y1, l] = GetPlotData(X3, Acc, Algo);
            legstr = [legstr, l];


        %% Set up axes
       
        PlotOnAxes(DA, Balance, x1, y1, iAlgo, ax, iplot, Acc);
        Best(iDS) = UpdateBest(Best(iDS), x1, y1, l, Acc, Balance);
                               
      
        end

l = legend(legstr,...
    'Location', 'eastoutside',...
    'Interpreter', 'latex',...
    'FontSize', lFS,...
    'EdgeColor', 0.9*[1 1 1]);

end


end

FixAxes(f);


plotPath = fullfile('..',p.Results,p.MOE,p.CrossVal,'Graphs');
plotName = sprintf('%s_%s_5.pdf', DS, p.Normalized);
Best(iDS).plotName = plotName;
if ~isfolder(plotPath), mkdir(plotPath), end
exportgraphics(f, fullfile(plotPath, plotName));
close(f)


end


for iDS = 1:length(DataSets)
    DS = DataSets(iDS); DA = DataAliases(iDS);
    fileID = GetFileID(DA, fileIDs);
    WriteFigureLatex(fileID, DS, DA, Best(iDS));
end
fclose all;

save(fullfile(plotPath, 'BestStruct.mat'), 'Best');



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
function Best = MakeBestStruct(DS, Accs)

for Acc = Accs
%Best.(Acc).DS = [];
Best.(Acc).Performance = 0;
Best.(Acc).Algo = [];
Best.(Acc).Mres = [];
Best.(Acc).Balance = [];
end

Best = repmat(Best, size(DS));

end
%=========================================================================

function Best = UpdateBest(Best, x1, y1, l, Acc, Balance)

[maxy1, imax] = max(y1); maxx1 = x1(imax); 

%if Acc == "accuracy", keyboard, end
if maxy1 >= Best.(Acc).Performance
    Best.(Acc).Performance = maxy1;
    Best.(Acc).Algo = l;
    Best.(Acc).Mres = maxx1;
    Best.(Acc).Balance = Balance;
else
    return 
end

end
%==========================================================================
function X= GetFiles(DS, p)

    
    folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, DS, p.HoldOut,'**', '*.mat');
    X = dir(folderpath); 
    mycontains = @(f,s) contains({X.(f)}, s); 
   
    XBench = X(mycontains('name','Benchmark') &...
               mycontains('name',p.Normalized));
    XBal = X(...
             mycontains('folder',p.Balance) &...
             mycontains('name',p.Nesting) & ...
             mycontains('name',p.Normalized) & ...
             mycontains('name',"Eigen-" + p.Trunc));

    X = [XBench; XBal];
end

%=======================================================================

function [x1, y1, l] = GetPlotData(X3, Acc, Algo)
TrimB = false;
 %% Get Better performing Kernel
            X4 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X3);
            [~, iBestAcc] = max( arrayfun(@(x) max(x.results.(Acc)), X4));
            X4 = X4(iBestAcc);
            
            if TrimB, [X4.parameters, X4.results] = TrimBenchmark(X4.parameters, X4.results); end

            switch X4.parameters.svm.kernal
                case true, l = "-RBF";
                case false, l = "-Lin";
            end
                  
            if ismember(Algo, ["MLS", "ACA-S", "ACA-L"])
                    x1 = X4.parameters.multilevel.Mres;
                    y1 = X4.results.(Acc);
                    l = Algo + l;
                    
            elseif Algo == "Benchmark"
                x1 = get(gca, 'XLim');
                [y1, ix] = max(X4.results.(Acc));
                y1 = [1 1] * y1;
                l = X4.parameters.misc.MachineList(ix);
                l = replace(l, '_Linear', '-Lin');
                l = replace(l, '_Radial', '-RBF');
            end 

end

function PlotOnAxes(DA, Balance, x1, y1, ...
                    iAlgo, ax, iplot,Acc)

YTicks = 0.5:0.1:1;

MarkerSize = 8;
tFS = 15;
yFS = 15;
xFS = 15;

YTickLabels = num2cell(YTicks); YTickLabels(1:2:end) = {''};
axNames = {'YLim', 'YGrid', 'YTickMode', 'ytick','YTickLabels', 'FontSize'};
axValues = {[0.5, 1], 'on', 'manual', YTicks, YTickLabels, yFS};
LineArgs = {'LineWidth', 3, 'Marker', 's', 'MarkerSize', MarkerSize, 'MarkerFaceColor', 'auto'};

minmax = @(x) [min(x) max(x)];
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

LineColors = [0.12, 0.21, 1; %MLS
            1, 0.04, 0.12; %ACA-S
            0.25, 0.25, 0.25; %ACA-L
            0.85, 0.67, 0.2]; %Benchmark;
if iplot <= 2
        title(Balance, 'Interpreter', 'latex', 'FontSize', tFS); 
end
        if ismember(iplot, [1 3])
        ylabel(capitalize(Acc), 'FontSize', yFS, 'Interpreter', 'latex');
        end
        cellfun(@(x,y) set(ax,x,y), axNames, axValues);
        
        %Set up data & x-axes
        LineColor = LineColors(iAlgo,:);
        plot(ax,x1,y1,'Color', LineColor, LineArgs{:});
        
        if ismember(iplot, [1 2])
            ax.XTickLabel = {};
        else 
            xlabel('$M_{res}$', 'Interpreter', 'latex', 'FontSize', xFS);
            ax.Position(2) = 0.18;
            if length(ax.XTickLabel) >= 7
                ax.XTickLabel(1:2:end) = {''};
            end
        end
        
        % if iplot == 1
        % annLeft = -0.05;
        % annWidth = 1;
        % annHeight = 0.05;
        % annBottom = 1; %0.86-annHeight;
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

end

%==========================================================================
function FixAxes(f)
minmax = @(x) [min(x) max(x)];
ax = findall(f,'type','axes');
minHeight = 0.8*min(arrayfun(@(x) x.Position(4), ax));
minWidth = min(arrayfun(@(x) x.Position(3), ax));
for i = 1:length(ax) 
    ichild = contains({ax(i).Children.DisplayName}, 'MLS');
    xl = minmax(ax(i).Children(ichild).XData);
    ax(i).XLim = xl;
    GetWindow(ax);
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
