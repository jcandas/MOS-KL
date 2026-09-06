function plotHyperparameterDistributions
close all

Accs = ["AUC", "accuracy"];

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


DSidx = [1:5, 11,9,8];
fileID = fopen('AHS_Frequencies.tex', 'w+');

for iDS = DSidx
    DS = DataSets(iDS); DA = DataAliases(iDS);

   
    fprintf(fileID, 'Processing %s\n', DS);

    
    
    X0 = GetHypData(DA, DS);
    if isempty(X0); continue, end
    [f, ax] = CreateFigure(DA);
    X1 = CreateMatrices(X0);
   
    PrintMode(fileID, X1);
    CreateMaps(X1, ax);
    FixFigure(ax);
    filePath = fullfile('..','results', 'Manual_Hyperparameter_Selection', 'Graphs', ...
        DS+"_HPD.pdf");
    exportgraphics(f, filePath);
    close(f)

    % % commandstr = "scp " + filePath + " \traja_dtdf01k@10.239.199.210:C:\Users\traja_dtdf01k\Downloads";
    % % system(commandstr);

end

end

%==========================================================================
%==========================================================================
function X = GetHypData(DA, DS)

load '..'/results/Manual_Hyperparameter_Selection/Graphs/Best.mat;

Accs = ["AUC", "accuracy"];
for Acc = Accs

iAcc = Accs == Acc;
X.(Acc) = [];
eigentags = ["smallest", "largest"];
svmonlys = [0 2];
%% Extract relevant info from Table
column = Table(:,DataAliases == DA,iAcc);
FINDER1 = column(RowNames == "FINDER1");
%isRBF = contains(FINDER1, "dagger"); %column(RowNames == "Kernel1") == "RBF";
isRBF = column(RowNames == "Kernel1") == "RBF";
isBalanced = contains(FINDER1, "*");
eigentag = char(eigentags(contains(FINDER1, "-L") + 1));
svmonly = svmonlys(contains(FINDER1, "ACA") + 1);

%% Fill parameters fields with Table info
methods = DefineMethods;
parameters = methods.all.initialization();
parameters.data.label = char(DS); 
parameters.data.name = [parameters.data.label, '.txt'];
parameters.multilevel.splitTraining = isBalanced; 
parameters.svm.kernal = isRBF; 
parameters.multilevel.eigentag = eigentag; 
parameters.multilevel.svmonly = svmonly; 
parameters.multilevel.chooseTrunc = true;

for iMOE = 8:11

MOE = str2func(sprintf('MethodOfEllipsoids_%d', iMOE));
methods.Multi2.ChooseTruncations = MOE; 
parameters = methods.all.filefunc(parameters, methods);

filePath = replace(parameters.datafolder, 'results','Truncations');
F = dir(filePath);

matchPattern = extractBefore(parameters.dataname, '-Eigen');
isMatch = contains({F.name}, matchPattern);
if ~any(isMatch)
    fprintf('Couldn''t find %s\n', DA);
    X = [];
    return
end
F = F(isMatch);

%X1 = load(fullfile(filePath, parameters.dataname));
X1 = load(fullfile(F.folder, F.name));
X.(Acc) = [X.(Acc), X1];

end

end


end
%==========================================================================
%==========================================================================
function [f, ax] = CreateFigure(DA)
close all

figHeight = 0.30;
figWidth = 0.85;
annWidth = 0.25; 
annHeight = 0.08;
annGap = 0.95; %Number between 0 and 1

dFS = 19;
hFS = 16;

f = figure('Units', 'Normalized', 'Position', [0.05, 0.95-figHeight, figWidth, figHeight]);
LeftMargin = 0.1; RightMargin = LeftMargin + 0.02;
WidthBetweenPlots = 0.05;
numCol = 4;
numRow = 2;
numPlots = numCol * numRow; 
Width = (1 - LeftMargin - RightMargin - (numCol-1)*WidthBetweenPlots)/numCol;
Left = LeftMargin;

Accs = ["AUC", "Accuracy"];


for i = 1:numPlots

    iCol = mod(i, numCol); if iCol == 0, iCol = numCol; end
    iRow = numRow + 1 - ceil(i/numCol);
    iRow2 = ceil(i/numCol);

    ax(i) = subplot(numRow, numCol, i);
    
    ax(i).Position(1) = Left;
    ax(i).Position(3) = Width; 
    ax(i).Position(2) = ax(i).Position(2) - iRow*0.03; 
    ax(i).Position(4) = 0.9*ax(i).Position(4);
    
    

    %% Set Titles
    if iCol == 1

        %% Set Header Position
        ax(i).Units = 'points';
        hWidth = ax(i).Position(4);
        hLeft = 0.65*ax(i).Position(1);
        hBottom = ax(i).Position(2);
        hHeight = 0.1*ax(i).Position(4);
        hPosition = [hLeft, hBottom, hWidth, hHeight];


        annotation('textbox', ...
            'String', Accs(iRow2), ...
            'Units', 'points',...
            'Interpreter', 'latex', ...
            'FontSize', hFS, ...
            'VerticalAlignment', 'middle', ...
            'HorizontalAlignment', 'center', ...
            'LineStyle', 'none',...
            'Rotation', 90, ...
            'Position', hPosition);
    
        ax(i).Units = 'normalized';
    end

    %% Update Left
    if mod(i, numCol) == 0
        Left = LeftMargin;
    else
        Left = Left + Width + WidthBetweenPlots;
    end

end

%% Set Title

annLeft = (1 - annWidth)/2;
plotsHeight = ax(1).Position(2) + ax(1).Position(4);
annBottom = plotsHeight*1.2; %annGap*(1 - plotsHeight  - annHeight);
annPosition = [annLeft annBottom annWidth annHeight];

ann = annotation('textbox', annPosition, ...
    'String', "", ...DA, ...
    'Interpreter', 'latex',...
    'FontSize', dFS,...
    'FontWeight', 'bold',...
    'VerticalAlignment', 'middle',...
    'HorizontalAlignment', 'center',...
    'LineStyle', 'none');
%nn = annotation('textbox', annPosition, 'String', DA);



end
%==========================================================================
%==========================================================================
function X1 = CreateMatrices(X0)

%X1 = X0;
Accs = string(fields(X0));

for Acc = Accs'
    
for i = 1:length(X0.(Acc))
    MAs = X0.(Acc)(i).MA;
    Mress = X0.(Acc)(i).Mres;
    uMA = unique(MAs);
    uMres = unique(Mress);
    %[uMA, uMres] = meshgrid(uMA, uMres);
    matrix = nan(length(uMA), length(uMres));

    % MARange = min(uMA):max(uMA);
    % MresRange = min(uMres):max(uMres);
    % matrix = nan(length(MARange), length(MresRange));

    for iMA = 1:length(uMA), for iMres = 1:length(uMres)
       MA = uMA(iMA); Mres = uMres(iMres);
       matrix(iMA, iMres) = sum(MAs == MA & Mress == Mres);
    end, end

    % for iMA = 1:length(MARange), for iMres = 1:length(MresRange)
    %    MA = MARange(iMA); Mres = MresRange(iMres);
    %    matrix(iMA, iMres) = sum(MAs == MA & Mress == Mres);
    % end, end

    



    
    matrix = matrix / length(MAs);
    %matrix = matrix / sum(matrix, [], 'all');
    matrix(matrix == 0) = nan;
    
    X1.(Acc)(i).MA = uMA;
    X1.(Acc)(i).Mres = uMres;
    % X1.(Acc)(i).MA = MARange;
    % X1.(Acc)(i).Mres = MresRange;
    X1.(Acc)(i).matrix = matrix;


    

end
end

end
%==========================================================================
%==========================================================================
function CreateMaps(X1, ax)

Accs = string(fields(X1));
numRow = length(Accs);
numCol = length(X1.(Accs(1)));
numAx = length(ax);

for i = 1:numAx
    axes(ax(i));

    iRow = ceil(i / numCol);
    iCol = mod(i,numCol); iCol(iCol == 0) = numCol;
    Acc = Accs(iRow);

    MA = X1.(Acc)(iCol).MA;
    Mres = X1.(Acc)(iCol).Mres; 
    matrix = X1.(Acc)(iCol).matrix;

    %Acc = Accs(iRow);

    %h = imagesc(Mres, MA, matrix); colormap jet %spring
    h = imagesc(1:length(Mres), 1:length(MA), matrix);
    h.AlphaData = ~isnan(matrix);
    clim(ax(i), [0, 1]);

    Ticks = ["XTick", "YTick"];
    HypFields = ["Mres", "MA"];
    
    colormap jet 

    for j = 1:2

    Tick = Ticks(j); 
    TickLabel = Tick + "Label";
    axTick = ax(i).(Tick);
    axTickLength = length(ax(i).(Tick));

    HypField = HypFields(j);
    HypList = X1.(Acc)(iCol).(HypField);
    HypLength = length(HypList);
    HypIdx = 1:HypLength;

    if axTickLength <= HypLength - 1
        newAxTicks = HypList(axTick);
        ax(i).(TickLabel) = string(newAxTicks);
    else %axTickLength > HypLength
      
        ax(i).(Tick) = HypIdx;
        ax(i).(TickLabel) = string(HypList);
    end

    end
    
    % if length(Mres) <= length(ax(i).XTick)
    %     ax(i).XTick = Mres;
    % end
    % if length(MA) <= length(ax(i).YTick)
    %     ax(i).YTick = MA;
    % end
    %ax(i).XTick = 1:length(Mres);
    % ax(i).XTickLabels = string(Mres);
    % 
    % ax(i).YTick = 1:length(MA);
    % ax(i).YTickLabels = string(MA);

    %ax(i).XTick = intersect(ax(i).XTick, Mres);
    %ax(i).YTick = intersect(ax(i).YTick, MA);

    
    

end

end
%==========================================================================
%==========================================================================
function FixFigure(f)

xFS = 13;
yFS = 13;
tFS = 15;
aFS = 10.5;

ax = findall(f, 'type', 'axes');
pos = cell2mat(get(ax, 'Position'));
numRow = numel(unique(pos(:,2)));
numCol = numel(unique(pos(:,1)));
numAx = length(ax);


Autos = arrayfun(@(x) sprintf("Auto-%s",x), ["I", "II", "III", "IV"]);
for i = 1:numAx
    
    axPos = ax(i).Position;
    iCol = mod(i, numCol); iCol(iCol == 0) = numCol;
    iRow = ceil(i/numCol);

    axes(ax(i)); 

    ax(i).XAxis.FontSize = aFS;
    ax(i).YAxis.FontSize = aFS;
    
    if iCol == 4
        c(iCol) = colorbar;
        c(iCol).Limits = [0 1];
        c(iCol).FontSize = aFS;
        c(iCol).Ticks = 0:0.25:1;
    elseif iCol == 1
        ylabel('$M_\mathbf A$', 'Interpreter', 'latex', 'FontSize', yFS);
    end   

    
   ax(i).TickLength = 2.5*ax(i).TickLength;

    if iRow == 1
        Auto = Autos(iCol);
        title(Auto, 'Interpreter', 'latex', 'FontSize', tFS);
    elseif iRow == 2
        xlabel('$M_{res}$', 'Interpreter', 'latex', 'FontSize', xFS);
    end

   
    


   

    ax(i).Color = [0.5,0.5,0.5];
    ax(i).Position = axPos;
    
end
end
%==========================================================================
%==========================================================================
function PrintMode(fileID, X1)

if false, return, end

Accs = string(fields(X1(1)));

for Acc = Accs'
    % [Max0, ~] = arrayfun(@(x) max(x.matrix, [], 'all'), X1.(Acc) );
    % [~, iMax0] = max(Max0);
    % 
    % 
    % 
    % matrix = X1.(Acc)(iMax0).matrix;
    % MA = X1.(Acc)(iMax0).MA;
    % Mres = X1.(Acc)(iMax0).Mres;
    % 
    % [Max1, iMax1] = max(matrix, [], 'all');
    % [iMres, iMA] = ind2sub(size(matrix), iMax1);
    % modeMA = MA(iMA);
    % modeMres = Mres(iMres);
    % 
    % fprintf('\t Mode MA: %d\n', modeMA);
    % fprintf('\t Mode Mres: %d\n', modeMres);
    % fprintf('\t Frequency: %d %% \n', round(100*Max1));
    fprintf(fileID, '%s:\n', Acc);
    [Max0, iMax0] = arrayfun(@(x) max(x.matrix, [], 'all'), X1.(Acc) );
    [iMA, iMres] = arrayfun(@(x,y) ind2sub(size(x.matrix), y), X1.(Acc), iMax0);
    modeMA = arrayfun(@(x,y) x.MA(y), X1.(Acc), iMA);
    modeMres = arrayfun(@(x,y) x.Mres(y), X1.(Acc), iMres);
    fprintf(fileID, '\t Mode MA: |');
    fprintf(fileID, ' %d |', modeMA); 
    fprintf(fileID, '\n\t Mode Mres: |');
    fprintf(fileID, ' %d |', modeMres);
    fprintf(fileID, '\n\t Frequency: |');
    fprintf(fileID, '%d %% |', round(100*Max0));
    fprintf(fileID, '\n');
   


end
 fprintf(fileID, '=====================================\n');

end