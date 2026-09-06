function ComputeWilcoxonRankAll

DSidx = [2:5];
p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitBox";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";
p.TrimB = false;
p.folder = fullfile("..", p.Results, p.MOE, p.CrossVal, "Tables");

%% Define Iterators
Accs = DefineAccs(6);
[DS, DS2] = DefineDatasets; 
DS = DS(DSidx); DS2 = DS2(DSidx); p.Truncs = p.Truncs(DSidx);
Algos = ["MLS", "ACA-S", "ACA-L"];
Machines = ["SVM_Linear-PCA", "SVM_Radial-PCA", "SVM_Linear", "SVM_Radial", "LogitBoost", "RUSBoost", "Bag"];


%% Define Arrays
BenchArray = nan(length(DS), length(Machines), numel(Accs));
FinderArray = nan(length(DS), length(Algos), numel(Accs));
WSRTArray = nan(length(Algos), length(Machines), numel(Accs));

%% Fill in Bench and Finder Arrays

for iDS = 1:length(DS)
    
    ds = DS(iDS); fprintf('Processing %s\n', ds);
    p.DS = ds; p.Trunc = p.Truncs(iDS);
   
    X = GetFiles(p);
    isBench = contains({X.name}, "Benchmark");
    BenchFiles = X(isBench); FinderFiles = X(~isBench);
    
for iRow = 1:numel(Accs)
        Acc = Accs(iRow);

    Bench = load(fullfile(BenchFiles.folder, BenchFiles.name));
    BenchArray(iDS, :, iRow) = Bench.results.(Acc);

for iAlgo = 1:length(Algos)


    Algo = Algos(iAlgo);
    AlgoF = FinderFiles(contains({FinderFiles.name}, Algo));
    Finder = arrayfun(@(x) load(fullfile(x.folder, x.name)), AlgoF);
    Best = arrayfun(@(x) max(x.results.(Acc)), Finder);
    [~,iBest] = max(Best);
    Finder = Finder(iBest);
    FinderArray(iDS, iAlgo, iRow) = max(Finder.results.(Acc));

end
end
end



%% Compute Wilcoxon Signed Rank Test statistics:

for iRow = 1:numel(Accs)
for iAlgo = 1:length(Algos)
for iBench = 1:length(Machines)
    FinderAcc = FinderArray(:,iAlgo,iRow);
    BenchAcc = BenchArray(:,iBench, iRow);
    WSRTArray(iAlgo, iBench, iRow) = signrank(BenchAcc, FinderAcc, 'tail', 'left');
end
end
end

%% Print Document
if ~isfolder(p.folder), mkdir(p.folder); end
path = fullfile(p.folder, "Wilcoxon_Signed_Rank_Table.tex");
fID = fopen(path, "w+"); edit(path);
isSVM = contains(Machines, "SVM"); isSVM = [isSVM ; ~isSVM];

%% Preamble
fprintf(fID, '\\begin{table}[h!]\n');
fprintf(fID, '\\scriptsize \\centering \n');
switch numel(Accs)
    case 2, fprintf(fID, '\\begin{tabular}{|c|c c|c c|} \n');
    case 6, fprintf(fID, '\\begin{tabular}{|c|c c|c c|c c|} \n');
end


%%

for iRow = 1:size(Accs,1), AccRow = Accs(iRow,:);
    PrintHeader(fID, AccRow);

for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);

    if mod(iAlgo, 2) == 1, fprintf(fID, '\\rowcolor{blue!20}\n'); end
    fprintf(fID, '%s ', Algo);

for iCol = 1:length(AccRow), iAcc = sub2ind(size(Accs), iRow, iCol);

for iSVM = 1:size(isSVM,1)

    pval = max(WSRTArray(iAlgo, isSVM(iSVM,:), iAcc));
    switch pval < 0.01
    case true, pval = "$<$0.01";
    case false, pval = sprintf("%0.2f", pval);   
    end
    fprintf(fID, '& %s ', pval);
        
 end
        

end
fprintf(fID, '\\\\ \n');

end
fprintf(fID, '\\hline ');
end

fprintf(fID, '\\hline \n');
fprintf(fID, '\\end{tabular} \n');
fprintf(fID, '\\caption{Wilcoxon signed rank test for each FINDER method}\n');
fprintf(fID, '\\label{Wilcoxon Table}\n');
fprintf(fID, '\\end{table}');



end


%==========================================================================
function Accs = DefineAccs(n)
Accs = ["AUC", "accuracy", "precision"; "recall", "specificity", "F1Score"];

if n == 2
    Accs = ["AUC", "accuracy"];
end

end
%==========================================================================
function [DS, DS2] = DefineDatasets


A = ["AD", "AD", "CN"]; B = ["CN", "LMCI", "LMCI"];
DS(1:2) = ["GCM", "newAD"]; DS2 = DS(1:2);

DS(3:5) = "Plasma_M12_" + A + B;
DS2(3:5) = "ADNI (" + A + " vs. " + B + ")";

DS(6:8) = "SOMAscan7k_KNNimputed_" + A + "_" + B;
DS2(6:8) = replace(DS2(3:5), "ADNI", "CSF");
end
%==========================================================================
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
%X = arrayfun(@(x) load(fullfile(X.folder, X.name)), X);
end
%==========================================================================
%==========================================================================
function PrintHeader(fID,Accs)

capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Accs = arrayfun(capitalize, Accs);
Accs = replace(Accs, "F1Score", "F1 Score");

fprintf(fID, '\\hline \\rowcolor{olive!40} \n');
fprintf(fID, 'Metric ');
fprintf(fID, '& \\multicolumn{2}{|c|}{%s} ',Accs);
fprintf(fID, '\\\\ \n');

fprintf(fID, '\\hline \n \\rowcolor{gray!20} \n\n');
fprintf(fID, 'Best ');
for i = 1:length(Accs)
fprintf(fID, '& SVM & Boost/Bag '); 
end
fprintf(fID, '\\\\ \n');
fprintf(fID, '\\hline  \n');
end
%==========================================================================
function PrintHeader3By2(fID)

fprintf(fID, '\\begin{table}[h!]\n');
fprintf(fID, '\\centering \n');
fprintf(fID, '\\begin{tabular}{|c|c c|c c|} \n');
fprintf(fID, '\\hline \\rowcolor{olive!40} \n');
fprintf(fID, '& \\multicolumn{2}{|c|}{AUC} & \\multicolumn{2}{|c|}{Accuracy} \\\\ \n');
fprintf(fID, '\\hline \n\n \\hline \n \\rowcolor{gray!20} \n\n');
fprintf(fID, '& Best SVM & Best Boost/Bag & Best SVM & Best Boost/Bag \\\\ \n');
fprintf(fID, '\\hline \n\n \\hline \n');
end