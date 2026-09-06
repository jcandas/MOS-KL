function WriteEffectSizeTables2
close all


p.DSidx = [1:8];
p.alpha = 0.01;
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitVariance2";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";
p.FontSize = "tiny";

p = CreateDataLabels(p);
p = FillArray(p);

%% Create Tables
p.Statistics = ["Effect Size", "p-Value"];
for i = 1:length(p.Statistics)
p.Statistic = p.Statistics(i);
p.TableName = replace(p.Statistic, " ", "_");

p = GetfID(p);
PrintHeader(p);
PrintBody(p);
PrintFooter(p);
fclose all;
end

end

%==========================================================================
function p = CreateDataLabels(p)


%% Enter Data Set Info:
a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];
DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;
DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
p.DS = DataSets;
p.DA = DataAliases;
p.isGenetic = ismember(p.DS, p.DS(1:2));
p.isPlasma = ismember(p.DS, p.DS(3:5));
p.isCSF = ismember(p.DS, p.DS(6:8));
p.Sources = ["Genetic", "Plasma", "CSF"];
fields = ["DS", "DA", "is" + p.Sources, "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

p.Balances = ["Balanced", "Unbalanced"];
p.Kernels = ["Linear", "Radial"];
p.Finder = ["MLS", "ACA-S", "ACA-L"]; 

p.AlgosSub = ["SVMs", "Boost/Bag", p.Finder]; 
p.Algos = p.AlgosSub; p.Algos(1:2) = "Benchmark";
p.AlgoFields = replace(p.AlgosSub, ["/", "-"], "_");

p.isFinder = ismember(p.AlgosSub, p.Finder);


%% Pit Algos Against Each Other;
AlgoMatrix = p.AlgosSub(:) + " vs. " + p.AlgosSub(:)';
i1 = 1:length(p.AlgosSub); i2 = i1(:) < i1(:)';
AlgoVersus = AlgoMatrix(i2);
delVs = ["SVMs vs. Boost/Bag", "ACA-S vs. ACA-L"];
AlgoVersus(ismember(AlgoVersus, delVs)) = [];
p.AlgoVersus = [];
for Algo = p.AlgosSub
    p.AlgoVersus = [p.AlgoVersus; ...
        AlgoVersus(startsWith(AlgoVersus, Algo))];
end

p.Accs = ["accuracy", "recall", "specificity", "precision"];
p.DataTable = nan(length(p.Accs), length(p.DS), length(p.AlgoVersus), 2);
p.AllTable = nan(length(p.Accs), length(p.AlgoVersus), 2);
p.ProtoAllTable = nan(length(p.Accs), length(p.AlgosSub), length(p.DS));

p.Bins = [0.2, 0.5, 0.8];
p.Colors = ["white", "red", "yellow", "green"];

nBins = length(p.Bins);
p.Bins = [-fliplr(p.Bins), p.Bins];
DarkColors = fliplr(p.Colors(2:end)) + "!20";
LightColors = p.Colors + "!60";
p.Colors = [DarkColors, LightColors];

end
%===========================================================================
function p = FillArray(p)
fprintf('Obtaining Performance Metrics\n');

for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS); 
    p.da = p.DA(iDS);
    p.Trunc = p.Truncs(iDS);
    fprintf("\t Processing %s\n", p.ds);

    p = GetPaths(p);
    [A,B] = meshgrid(p.SVMs.parameters.data.NAvals,...
                     p.SVMs.parameters.data.NBvals);
    p.pairs = [A(:), B(:)];
    p.PerformanceArray = nan(size(p.pairs,1), length(p.Algos), length(p.Accs));

for iAlgo = 1:length(p.Algos)
    AlgoSub = p.AlgosSub(iAlgo);
    AlgoField = p.AlgoFields(iAlgo);
    
    iLevel = p.(AlgoField).BestIdx;
    
    
for iAcc = 1:length(p.Accs)
    Acc = p.Accs(iAcc);
    
    p.ProtoAllTable(iAcc, iAlgo, iDS) = p.(AlgoField).results.(Acc)(iLevel);

for ipair = 1:size(p.pairs,1)
    iA = p.pairs(ipair,1); iB = p.pairs(ipair,2);
    results.array = p.(AlgoField).results.array(iA,iB,iLevel,:,:);
    results = ComputeResultsAUC(results);
    results = ComputeResultsAccuracy(results);
    if isnan(results.(Acc)), keyboard, end
    p.PerformanceArray(ipair, iAlgo, iAcc) = results.(Acc);   
end

end,end

%%
for iAV = 1:length(p.AlgoVersus)
    AV = p.AlgoVersus(iAV);
    AV1 = extractBefore(AV, " vs. "); 
    AV2 = extractAfter(AV, " vs. ");
    i1 = p.AlgosSub == AV1; i2 = p.AlgosSub == AV2;

for iAcc = 1:length(p.Accs)
    pm1 = squeeze(p.PerformanceArray(:,i1,iAcc));
    pm2 = squeeze(p.PerformanceArray(:,i2,iAcc));

    EF = meanEffectSize(pm2, pm1, Paired = true, Effect = "cohen");
    p.DataTable(iAcc, iDS, iAV, 1) = EF.Effect;
    p.DataTable(iAcc, iDS, iAV, 2) = signrank(pm2, pm1, tail = "right");

    if iDS == length(p.DS)
    pm3 = squeeze(p.ProtoAllTable(iAcc,i1,:));
    pm4 = squeeze(p.ProtoAllTable(iAcc, i2,:));
    EF2 = meanEffectSize(pm4, pm3, Paired = true, Effect = "cohen");
    p.AllTable(iAcc, iAV, 1) = EF2.Effect;
    p.AllTable(iAcc, iAV, 2) = signrank(pm4, pm3, tail = "right");
    end
    
end
end

end

end
%==========================================================================
function p = GetPaths(p)

folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X0 = dir(folderpath); 
Paths = fullfile({X0.folder}, {X0.name}); 

idx1 = contains(Paths, p.Normalized)...
    & (contains(Paths, "Eigen-" + p.Trunc) ...
    | (contains(Paths, "Benchmark"))) ;

Paths = Paths(idx1);

for iAlgo = 1:length(p.Algos)
    Algo = p.Algos(iAlgo);
    AlgoSub = p.AlgosSub(iAlgo);
    AlgoField = p.AlgoFields(iAlgo);
    idx2 = contains(Paths, Algo);
    X1 = cellfun(@load, Paths(idx2));    
    [~, im] = min(arrayfun(@(x) min(x.results.errorRate), X1));
    X2 = X1(im);
    if length(X2) ~= 1, keyboard, end
    p.(AlgoField) = X2;

    if ismember(AlgoSub, p.Finder)
        [~,iL] = min(p.(AlgoField).results.errorRate);
    else
        allMachines = p.(AlgoField).parameters.misc.MachineList;
        isSVM = contains(allMachines, "SVM");
        if AlgoSub == "Boost/Bag", isSVM = ~isSVM; end
        fMachines = allMachines(isSVM);
        [~,iM] = min(p.(AlgoField).results.errorRate(isSVM));
        BestMachine = fMachines(iM);
        iL = find(allMachines == BestMachine);
    end

    p.(AlgoField).BestIdx = iL;
    
end


end
%==========================================================================
function p = GetfID(p)
p.TableFolder = fullfile("..",p.Results,p.MOE, p.CrossVal, "Tables");

if ~isfolder(p.TableFolder), mkdir(p.TableFolder), end
path1 = fullfile(p.TableFolder, p.TableName + ".tex");
path2 = fullfile(p.TableFolder, p.TableName + "_all.tex");
p.fID1 = fopen(path1, "w+");
p.fID2 = fopen(path2, "w+");
edit(path1); edit(path2);
end
%==========================================================================
function PrintHeader(p)

%% Print Table "preamble"
fprintf(p.fID1, "\\begin{%s}\n", p.FontSize);
fprintf(p.fID1, '\\begin{longtable}[c]\n');

nDS = arrayfun(@(f) sum(p.("is" + f)), p.Sources);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.3em}",[1 x])), [1 nDS]);
columnstr(1) = "C{4.8em}";
columnstr = "|" + strjoin(columnstr,"||") + "|";

fprintf(p.fID1, '{%s}\n',columnstr);
fprintf(p.fID1, '\\hline \n \\rowcolor{olive!40}\n Metric');

cellchars = repmat("|c||", size(p.Sources));
cellchars(end) = "|c|";
for i = 1:length(p.Sources)
fprintf(p.fID1, " & \\multicolumn{%d}{%s}{%s}",...
    nDS(i), cellchars(i), p.Sources(i));
end
fprintf(p.fID1, '\\\\\n \\hline \n\n \\rowcolor{gray!20} \n\n');

%% print actual datasets
pattern = ("ADNI "| "CSF "| "("| ")");
DataAliases = arrayfun(@(x) replace(x,pattern, ''), p.DA);


for i = 1:length(p.Sources)
Source = p.Sources(i);
DA = DataAliases(ismember(p.DS, p.(Source).DS));
fprintf(p.fID, "& %s ", DA);
end
fprintf(p.fID, " \\\\ \n \\hline");
% fprintf(p.fID1, "& %s ", DataAliases);
% fprintf(p.fID1, " \\\\ \n \\hline");

%% Print Overall Table
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
fprintf(p.fID2, "\\begin{%s}\n", p.FontSize);
fprintf(p.fID2, '\\begin{longtable}[c]\n');
fprintf(p.fID2, '{|c');
fprintf(p.fID2, "%s", repmat("|c|", size(p.Accs')) );
fprintf(p.fID2, "}\n\\hline\n\\rowcolor{olive!40}\nMethod 1 vs. Method 2 ");
fprintf(p.fID2, " & %s", capitalize(p.Accs));
fprintf(p.fID2, "\\\\ \\hline \n");
end

%==========================================================================
function PrintBody(p)
fprintf(p.fID2, "\\hline \n");
for iAV = 1:length(p.AlgoVersus)
    p.AV = p.AlgoVersus(iAV);
    %% Print Row Header;
    fprintf(p.fID1, "\n\\hline " + ...
        "\\rowcolor{gray!40}" + ...
        "\\multicolumn{%d}{|c|}{%s}" + ...
        "\\\\ \n \\hline ", ...
        length(p.DS) + 1, p.AV);

    fprintf(p.fID2, "%s", p.AV);
    PrintData(p);
end
fprintf(p.fID2, "\\hline\n");
end
%==========================================================================
function PrintData(p)

capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Accs = p.Accs;
Accs = replace(Accs, "F1Score", "F1 Score");
Accs = capitalize(Accs);

iAV = find(p.AlgoVersus == p.AV);
iStat = find(p.Statistics == p.Statistic);
stats{1} = p.DataTable(:,:, iAV, iStat);
stats{2} = p.AllTable(:,iAV,iStat);

stats = cellfun(@squeeze, stats, 'UniformOutput', false);
stats{2} = stats{2}';



for i = 1:2
    switch p.Statistic
        case "Effect Size"
ColorCodes = discretize(stats{i}, [-Inf, p.Bins, Inf], 'categorical',...
                        p.Colors);
stats{i} = arrayfun(@(c,s) sprintf("\\cellcolor{%s} %0.2f", c, s),...
    string(ColorCodes), stats{i});

        case "p-Value"
isSig = stats{i} <= p.alpha;
stats{i} = arrayfun(@(x) sprintf("%0.2f",x), stats{i});
stats{i}(isSig) = sprintf("\cellcolor{green!60}{%0.2f}", p.alpha);
    end
end


%% First Table
fprintf(p.fID1, "\n\\hline \n");
for iA = 1:length(Accs)
    % if p.Statistic == "p-Value" &&  mod(iA,2) == 1
    %     fprintf(p.fID1, "\n\\rowcolor{blue!20}\n");
    % end
    fprintf(p.fID1, Accs(iA));
    fprintf(p.fID1, " & %s ", stats{1}(iA,:));
    fprintf(p.fID1, "\\\\ \n");
end
fprintf(p.fID1, " \\hline\n");


%% Second Table
fprintf(p.fID2, " & %s", stats{2});
fprintf(p.fID2, "\\\\ \n");

end
%==========================================================================
function PrintFooter(p)

allstr = ["", "_all"];
for i = 1:2
labelString = p.TableName + allstr(i);
captionName = labelString + "_caption_string.txt";
captionFile = fullfile(p.TableFolder, captionName);
c = readlines(captionFile);
captionString = c(1); footnoteString = c(2);

fID = p.("fID" + i);
fprintf(fID, '\\caption{%s\\protect \\footnotemark}\n', captionString);
% switch i 
%     case 1, fprintf(fID, "\\label{%s}\n", p.TableName);
%     case 2, fprintf(fID, "\\label{%s}\n", p.TableName + "_all");
% end
fprintf(fID, "\\label{%s}\n", labelString);
fprintf(fID, '\\end{longtable} \n');
fprintf(fID, "\\end{%s}\n\n", p.FontSize);
fprintf(fID, "\\footnotetext{%s}", footnoteString);
end

end
%==========================================================================