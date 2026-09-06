function WriteAUCTableMain
close all

p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitBox";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

% p.rF = 'results2';
% p.nesting = 'Inner-Nesting';

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



DA2 = [repmat("", size(DataAliases)) ; DataAliases ];




Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];
Algos = ["MLS", "ACA-L", "ACA-S", "Benchmark"];

T = CreateEmptyTable(DataAliases, Accs);



for iDS = 1:length(DataSets)
    DS = DataSets(iDS); DA = DataAliases(iDS);
    fprintf('Processing %s \n', DA);

    p.DS = DS; p.DA = DA; p.Trunc = p.Truncs(iDS);
    X1 = GetFiles(p);
 
 for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);
 for iAcc = 1:length(Accs), Acc = Accs(iAcc);   

     X2 = X1(contains({X1.name}, Algo));
     X3 = arrayfun(@(x) load(fullfile(x.folder, x.name)), X2);
     if isempty(X3), keyboard, end

     if Algo == "Benchmark"
         isSVM = contains(X3.parameters.misc.MachineList, "SVM");
         T.(Acc)("SVM",:).(DA){1} = X3.results.(Acc)(isSVM)';
         T.(Acc)("Boost/Bag",:).(DA){1} = X3.results.(Acc)(~isSVM)';
     else
         X4 = arrayfun(@(x) max(x.results.(Acc)), X3);
         T.(Acc)(Algo, :).(DA){1} = X4;
     end

end

end
end

T = GetBestClassifier(T);
fileID = GetFileID(p,T);
PrintTable(fileID, T);
end



%==========================================================================
function T1 = CreateEmptyTable(DataAliases, Accs)
T0 = cell(5,length(DataAliases));
T0 = cell2table(T0);
T0.Properties.RowNames = ["MLS", "ACA-S", "ACA-L", "SVM", "Boost/Bag"];
T0.Properties.VariableNames = DataAliases;
%T1 = struct('AUC', T0, 'accuracy', T0);
for acc = Accs
    T1.(acc) = T0;
end

end
%==========================================================================

function fileID = GetFileID(p,T)
%TablePath = fullfile('..',rF,'Manual_Hyperparameter_Selection', 'Kfold', 'Tables');
TablePath = fullfile('..',p.Results,p.MOE, p.CrossVal, 'Tables');
if ~isfolder(TablePath), mkdir(TablePath), end
path = fullfile(TablePath, 'Performance_Table.txt');
fileID = fopen(path, "w+");
edit(path);
save(fullfile(TablePath, "Performance_Table.mat"), "T");
end

%==========================================================================

% function X = GetFiles(DS, nesting)
%     %nesting = 'Unnested';
%     resultFolder = 'Manual_Hyperparameter_Selection';
%     CrossVal = 'Kfold';
%     folderpath = fullfile('..', 'results', resultFolder, CrossVal, DS, 'Leave_5_out','**', '*.mat');
%     X = dir(folderpath); 
% end

function X= GetFiles(p)

folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.DS, p.HoldOut,'**', '*.mat');
X = dir(folderpath); 
mycontains = @(f,s) contains({X.(f)}, s); 

XB = X(mycontains('name', 'Benchmark') & ...
       mycontains('name', p.Normalized));

XM = X(...
    ...mycontains('folder',p.Balance) &...
    mycontains('name',p.Nesting) & ...
    mycontains('name',p.Normalized) & ...
    mycontains('name',"Eigen-" + p.Trunc));

X = [XB(:); XM(:)];

end

%==========================================================================

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

%==========================================================================
function PrintHeader(fileID, T)



%Print Table "preamble"
fprintf(fileID, ['\\begin{table} [H]\n',... 
'\\centering\n',...
'\\footnotesize\n']);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.6em}",[1 x])), [1 2 3 3]);
columnstr(1) = "C{4.2em}";
columnstr = "|" + strjoin(columnstr,"|") + "|";

fprintf(fileID, '\\begin{tabular}\n {%s}\n',columnstr);
fprintf(fileID, '\\hline \n \\rowcolor{olive!40}\n');
fprintf(fileID, ['Method & \\multicolumn{2}{|c|}{Genetic}'...
    '& \\multicolumn{3}{|c|}{Proteomic (ADNI)} '...
    '& \\multicolumn{3}{|c|}{CSF}\\\\ \n']);
fprintf(fileID, '\\hline \n\n \\rowcolor{gray!20} \n\n');


%print actual datasets
DataSets = string(T.Properties.VariableNames);
pattern = ("ADNI "| "CSF "| "("| ")");
DataSets = arrayfun(@(x) replace(x,pattern, ''), DataSets);

fprintf(fileID, '& %s ', DataSets);
fprintf(fileID, ' \\\\ \n \\hline');
end
%==========================================================================

function PrintRow(fileID, T)


Data = table2array(T); [maxData, im] = max(Data,[],1);
ismax = abs(Data - maxData) < 0.0005;

Data = arrayfun(@(x) sprintf("%0.3f",x), Data);
Data(ismax) = arrayfun(@(x) sprintf("\\textbf{%s}",x), Data(ismax));

fprintf(fileID, '\\hline \n\n');
for i = 1:size(Data,1)
if mod(i,2) == 1, fprintf(fileID, '\\rowcolor{blue!20}\n'); end

fprintf(fileID, '%s', T.Properties.RowNames{i});
fprintf(fileID, ' & %s', Data(i,:));
fprintf(fileID, '\\\\ \n');
    
end



fprintf(fileID, '\\hline ');

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
function PrintAccuracyRow(fileID, Acc, T)
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

Acc = replace(Acc, "precisionA", "Precision");

fprintf(fileID, [' \\hline' ...
    '\\rowcolor{gray!40}' ...
    '\\multicolumn{%d}{|c|}{%s}' ...
    '\\\\ \\hline '], ...
    width(T) + 1, capitalize(Acc));
end
%==========================================================================
function T = GetBestClassifier(T)

for Acc = ["AUC", "accuracy"]
   T1 = table2cell(T.(Acc));
   T2 = cellfun(@max, T1);
   T3 = array2table(T2);
   for i = ["RowNames", "VariableNames"]
       T3.Properties.(i) = T.(Acc).Properties.(i);
   end
   T.(Acc) = T3;
end



end
%==========================================================================
function PrintTable(fileID, T)


MLA = ["L-PCA", "R-PCA", "SVM-L", "SVM-R", "Log", "RUS", "BAG"];


PrintHeader(fileID, T.AUC);


for Acc = ["AUC", "accuracy"]
    PrintAccuracyRow(fileID, Acc, T.(Acc));
    PrintRow(fileID, T.(Acc));
end


end
%==========================================================================


