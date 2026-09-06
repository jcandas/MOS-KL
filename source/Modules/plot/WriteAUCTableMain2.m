function WriteAUCTableMain2
close all


rF = 'results';
nesting = 'Inner-Nesting';

%% Load Table Data
plotPath = fullfile('..',rF,'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
load(fullfile(plotPath, 'Bar_Graph_Data.mat'));
Headers = string(Headers);
isntFinder = contains(Headers, ("SVM"|"Boost"|"BAG"));
%McNemar(:,isntFinder,:,:) = 1;
%Wilcoxon(:,isntFinder,:,:) = 1; 
%barArray indexing is (iDataSets, iAlgo, iBalance, iAccuracy);

%% Define Data Sets and Data Aliases
DataSets = ["GCM", "newAD", ...
            arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]),...
            arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["AD_CN", "AD_LMCI", "CN_LMCI", "EMCI_LMCI", "AD_EMCI"]) ];

DataAliases = ["GCM", "newAD", ...
                arrayfun(@(x) sprintf("ADNI (%s)", x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"]),...
               arrayfun(@(x) sprintf("CSF (%s)",x),...
               ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI", "EMCI vs. LMCI",  "AD vs. EMCI"])...
               ];


DSidx = 1:8;
DataSets = DataSets(DSidx);
DataAliases = DataAliases(DSidx);


%DA2 = [repmat("", size(DataAliases)) ; DataAliases ];

%% Define Balancing Conditions, Accuracy measures, and Algorith Groups

Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];
Algos = ["MLS", "ACA-L", "ACA-S", "SVM", ("Boost"|"BAG")];

% labelsArray = cell(size(size(barArrayOld)));
% [labelsArray{:}] = ndgrid(DataAliases, Headers, Balances, Accs);
% [barArray, imax] = max(barArrayOld, [], 3);
%labaelsArray = cellfun(@(x) x(imax), labelsArray, 'UniformOutput', false);


%T = CreateEmptyTable(DataAliases);

fileID = GetFileID(rF);
PrintHeader(fileID, DataAliases);
for Acc = Accs

PrintAccuracyRow(fileID, Acc, DataAliases);

%% Select the data containing the pertinent accuracy measure
barArrayAcc = barArrayOld(:,:,:,Accs == Acc); 
%McNemarAcc = McNemar(:,:,:,Accs == Acc);
%WilcoxonAcc = Wilcoxon(:,:,:,Accs == Acc);

[BestBarArray, IsBalanced] = max(barArrayAcc, [], 3); %Find the maximum over both balancing conditions
BestBarArray = BestBarArray'; %Transpose so the data assumes the same shape as the table
%IsBalanced = cat(3,IsBalanced == 1, IsBalanced == 2);
%IsBalanced = IsBalanced;
BestMcNemar = nan(size(IsBalanced));
BestWilcoxon = BestMcNemar;
for i = 1:2
    X = McNemarAcc(:,:,i);
    BestMcNemar(IsBalanced == i) = X(IsBalanced == i);
    Y = WilcoxonAcc(:,:,i);
    BestWilcoxon(IsBalanced == i) = Y(IsBalanced == i);
    % BestMcNemar(IsBalanced == i) = McNemarAcc(IsBalanced == i,i);
    % BestWilcoxon(IsBalanced == i) = WilcoxonAcc(IsBalanced == i,i);
end
BestMcNemar = BestMcNemar';
BestWilcoxon = BestWilcoxon';

BestBarArrayReduced = nan(length(Algos), length(DataAliases));
BestMcNemarReduced = BestBarArrayReduced;
BestWilcoxonReduced = BestBarArrayReduced;

for iAlgo = 1:length(Algos)

%% Extract Relevant Row Data
Algo = Algos(iAlgo);
AlgoIdx = contains(Headers, Algo);
BestBarArrayAlgo = BestBarArray(AlgoIdx,:);
BestMcNemarAlgo = BestMcNemar(AlgoIdx,:);
BestWilcoxonAlgo = BestWilcoxon(AlgoIdx,:);
%[BestBarArrayReduced(iAlgo,:), iBest] = max(BestBarArrayAlgo,[],1);
BestBarArrayReduced(iAlgo,:) = max(BestBarArrayAlgo,[],1);
iBest = BestBarArrayAlgo == BestBarArrayReduced(iAlgo,:);
BestMcNemarReduced(iAlgo,:) = BestMcNemarAlgo(iBest);
BestWilcoxonReduced(iAlgo,:) = BestWilcoxonAlgo(iBest);

end
BestBarArrayReduced = 0.001 * round(1000*BestBarArrayReduced);
BestBarArrayOverAllAlgos = max(BestBarArrayReduced, [], 1);
IsBestBarArray = BestBarArrayReduced == BestBarArrayOverAllAlgos;

%% Produce superscripts corresponding to significance levels
Statistics = cat(3, BestMcNemarReduced, BestWilcoxonReduced);
SignificanceKeys = repmat("", size(BestBarArrayReduced));
%Superscripts = ["*","\dagger"];
Superscripts = ["*"];
Significances = [0.01];
if Acc == "accuracy"
for i1 = 1:length(Superscripts)
    for i2 = 1:length(Significances)
       IsSignificant = Statistics(:,:,i1) < Significances(i2);
       SignificanceKeys(IsSignificant) = SignificanceKeys(IsSignificant) + Superscripts(i1);
    end
end
end

SignificanceKeys(SignificanceKeys ~= "") = ...
arrayfun(@(x) sprintf("$^{%s}$",x), ...
SignificanceKeys(SignificanceKeys ~= ""));


% IsMcNemarSignificant95 = BestMcNemarReduced < 0.05 & BestMcNemarReduced >= 0.01;
% IsMcNemarSignificant99 = BestMcNemarReduced < 0.01;
% IsWilcoxonSignificant95 = BestWilcoxonReduced < 0.05 & BestWilcoxonReduced >= 0.1;
% IsWilcoxonSignificant99 = BestWilcoxonReduced < 0.01;

%% Convert numerical data to string data
TableValues = arrayfun( @(x) sprintf("%0.3f",x), BestBarArrayReduced);
TableValues(IsBestBarArray) = arrayfun( @(x) sprintf("\\textbf{%0.3f}", x), BestBarArrayReduced(IsBestBarArray));
TableValues = arrayfun(@(x) sprintf(" & %s", x), TableValues);
TableValues = TableValues + SignificanceKeys;

% TableValues(IsMcNemarSignificant95) = arrayfun(@(x) sprintf("%s^*",x), ...
%     TableValues(IsMcNemarSignificant95));
% TableValues(IsMcNemarSignificant99) = arrayfun(@(x) sprintf("%s^{**}",x), ...
%     TableValues(IsMcNemarSignificant99));

for iAlgo = 1:length(Algos)
    Algo = Algos(iAlgo);
if mod(iAlgo,2) == 1, fprintf(fileID, "\\rowcolor{blue!20} \n"); end
switch isequal(Algo, ("Boost"|"BAG"))
    case false
        fprintf(fileID, '%s ', extractBetween(string(Algo),"""", """") );
        
    case true
        fprintf(fileID, '%s ', 'Other');
        
end

fprintf(fileID, ' %s', TableValues(iAlgo,:));
fprintf(fileID, ' \\\\ \n');
end
fprintf(fileID, "\\hline ");
end



end

% for iDS = 1:length(DataSets)
%     DS = DataSets(iDS);
%     DA = DataAliases(iDS);
%     fprintf('Processing %s \n', DA);
%     %X1 = GetFiles(DS, nesting);
% 
%  for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);
%  for iAcc = 1:length(Accs), Acc = Accs(iAcc);   
% 
%      X2 = X1(contains({X1.name}, Algo));
%      X3 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X2);
% 
%      if Algo == "Benchmark"
%          T.(Acc)(Algo, :).(DA){1} = X3.results.(Acc)';
%      else
%          X4 = arrayfun(@(x) max(x.results.(Acc)), X3);
%          T.(Acc)(Algo, :).(DA){1} = X4;
%      end
% 
% end
% 
% end
% end
% 
% T = GetBestClassifier(T);
% fileID = GetFileID(rF);
% PrintTable(fileID, T);
% end



%==========================================================================
function T1 = CreateEmptyTable(DataAliases)
T0 = cell(5,length(DataAliases));
T0 = cell2table(T0);
T0.Properties.RowNames = ["MLS", "ACA-S", "ACA-L", "Benchmark", "Max"];
T0.Properties.VariableNames = DataAliases;
T1 = struct('AUC', T0, 'accuracy', T0);
end
%==========================================================================

function fileID = GetFileID(rF)
TablePath = fullfile('..',rF,'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs', 'Performance_Table.tex');
fileID = fopen(TablePath, "w+");
end

%==========================================================================

function X = GetFiles(DS, nesting)
    %nesting = 'Unnested';
    resultFolder = 'Manual_Hyperparameter_Selection';
    CrossVal = 'Kfold';
    folderpath = fullfile('..', 'results2', resultFolder, CrossVal, DS);
    X = dir(folderpath); X(matches({X.name}, [".", ".."])) = [];
    Leave_K_out = {X.name};
    K = cellfun(@(x) extractBetween(x, 'Leave_', '_out'), Leave_K_out);
    Ks = cellfun(@str2num, K); %Ks = Ks(Ks > 1);
    [K, iK] = min(Ks); %min(cellfun(@str2num, K));
    Leave_K_out = sprintf('Leave_%d_out', K);%Leave_K_out{iK};
    folderpath = fullfile(folderpath, Leave_K_out, '**');
    X = dir(folderpath); 
    X(matches({X.name}, [".", ".."])) = []; 
    X(~contains({X.name}, '.mat')) = [];
    XB = X(contains({X.name}, 'Benchmark'));
    XB(contains({XB.name}, 'PCA')) = [];
    XN = X(contains({X.name}, nesting));
    X = [XB; XN];
end

%==========================================================================

function nesting = GetNesting(X)

X(contains({X.name}, 'Benchmark')) = [];
%svmonly = arrayfun(@(x) x.parameters.multilevel.svmonly, X);
load(fullfile(X(1).folder, X(1).name));


switch parameters.multilevel.nested
    case 0, nesting = 'Unnested';
    case 1, nesting = 'Inner-Nesting';
    case 2, nesting = 'Outer-Nesting';
end
end

%==========================================================================
function PrintHeader(fileID,DA)

columnstr = repmat("",[1 length(DA)+2]);
columnstr([3 7]) = "|";
columnstr(columnstr == "") = "C{3.5em}";
columnstr = strjoin(columnstr);


%Print Table "preamble"
fprintf(fileID, ['\\begin{table} [h] \n'...
    '\\centering \n'...
    '\\begin{tabular}{|C{4.9em}| %s |} \n'...
    '\\hline \n'], columnstr); 

%Print macro grouping of datasets
fprintf(fileID, [ ...
    '\\rowcolor{olive!40} \n'...
    'Method'...
    ' & \\multicolumn{2}{|c|}{Genetic}' ...
    ' & \\multicolumn{3}{|c|}{Proteomic (ADNI)}' ...
    ' & \\multicolumn{3}{|c|}{CSF}' ...
    '\\\\ \n \\hline \n']);

%print actual datasets
pattern = ("ADNI "| "CSF "| "("| ")");
DA = arrayfun(@(x) replace(x,pattern, ''), DA);

fprintf(fileID,  '\\rowcolor{gray!20} \n  ');
fprintf(fileID, '& %s ', DA);
fprintf(fileID, ' \\\\ \n \\hline');
end
%==========================================================================

function PrintRow


%barArray Indexing: (iDataSets, iAlgo, iBalance, iAccuracy);





% MLA = ["L-PCA", "R-PCA", "SVM-L", "SVM-R", "Log", "RUS", "BAG"];
% fprintf(fileID, '%s ', T.Properties.RowNames{1});
% %Data = table2array(T); [maxData, im] = max(Data);
% 
% % maxData = varfun(@(x) max(x{1}), T);
% % maxData = table2array(maxmaxData);
% % [maxData, im] = max(Data);
% 
% 
% for id = string(T.Properties.VariableNames)
%     Data = T(1,:).(id){1};
%     [Data2, im] = max(Data);
%     maxData = T("Max",:).(id){1};
% 
%     if Data2 == maxData
%         fprintf(fileID, ' & \\textbf{%0.3f}', Data2);
%     else
%         fprintf(fileID, ' & %0.3f', Data2);
%     end  
% 
% if T.Properties.RowNames{1} == "Benchmark"
% fprintf(fileID, ' %s', MLA(im));
% end
% end
% 
% 
% 
% fprintf(fileID, ' \\\\ \n');

end
%==========================================================================
function PrintDataSetHeader(fileID, T)
end
%==========================================================================
function PrintRowColor(fileID, DS)
methods = DefineMethods;

   if ismember(DS, ["GCM", "newAD"])
        rowColor = 'violet!30';
   elseif ismember(DS, methods.data.ADNI_files)
        rowColor = 'blue!20';
   elseif ismember(DS, methods.data.CSF_files)
        rowColor = 'teal!40';
   end

   fprintf(fileID, '\\rowcolor{%s} \n', rowColor);
end
%==========================================================================
function bool = RestartColoring(DS)
methods = DefineMethods;
bool = any(...
    [strcmp(DS, "GCM"),     
    ismember(DS, methods.data.ADNI_files{1}),
    ismember(DS, methods.data.CSF_files{1})]...
   )
end
%==========================================================================
function PrintAccuracyRow(fileID, Acc, DA)
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

fprintf(fileID, [' \\hline ' ...
    '\\rowcolor{gray!40}' ...
    '\\multicolumn{%d}{|c|}{%s}' ...
    '\\\\ \\hline \\hline \n \n'], ...
    length(DA) + 1, capitalize(Acc));
end
%==========================================================================
function T = GetBestClassifier(T)

for Acc = ["AUC", "accuracy"]
   T1 = table2cell(T.(Acc));
   T2 = cellfun(@max, T1(1:4,:));
   T3 = max(T2, [], 1);
   T1(end,:) = num2cell(T3);
   T4 = cell2table(T1);
   for i = ["RowNames", "VariableNames"]
       T4.Properties.(i) = T.(Acc).Properties.(i);
   end
   T.(Acc) = T4;
end



end
%==========================================================================
function PrintTable(fileID, T)


MLA = ["L-PCA", "R-PCA", "SVM-L", "SVM-R", "Log", "RUS", "BAG"];


PrintHeader(fileID, T.AUC);


for Acc = ["AUC", "accuracy"]
    PrintAccuracyRow(fileID, Acc, T.(Acc));
for ir = 1:height(T.AUC)-1
    if mod(ir, 2) == 1, fprintf(fileID, '\\rowcolor{blue!20} \n'); end
    PrintRow(fileID, T.(Acc)([ir end],:));
end
fprintf(fileID, '\n \\hline \n');
end


end
%==========================================================================


