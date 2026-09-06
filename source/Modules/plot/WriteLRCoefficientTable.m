function WriteLRCoefficientTable
close all

rF = 'results';
nesting = 'Inner-Nesting';
alpha = 0.01;
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

[DataSets, DataAliases] = CreateDataLabels();
DataSets = DataSets(DSidx); DataAliases = DataAliases(DSidx); p.Truncs = p.Truncs(DSidx);

Balances = ["Balanced", "Unbalanced"];
Kernels = ["Linear", "Radial"];
[Balances, Kernels] = meshgrid(Balances, Kernels);
BalanceKernels = Balances(:) + ", " + Kernels(:);

Algos = ["MLS", "ACA-L"]; Accs = ["AUC", "accuracy", "precision", "recall", "specificity", "F1Score"];
[Accs, Algos] = meshgrid(Accs, Algos);
AlgoAccs = Algos(:) + " " + Accs(:);

T = nan(length(BalanceKernels), length(DataSets), length(AlgoAccs));

for iDS = 1:length(DataSets)
    DS = DataSets(iDS); DA = DataAliases(iDS);
    p.DS = DS; p.Trunc = p.Truncs(iDS);
    fprintf('Processing %s \n', DA);

for iBK = 1:length(BalanceKernels)
    BK = BalanceKernels(iBK);
    p.BK = BK;

for iAA = 1:length(AlgoAccs)
    AA = AlgoAccs(iAA);
    p.AA = AA;
    X1 = GetFiles(p);
    T(iBK, iDS, iAA) = GetLCPValue(X1, AA); %max(X1.results.precisionA);

end
end


end

fID = GetfID(p);
PrintHeader(fID, DataAliases);

%% Embolden significant p values 
isSig = T < alpha;
T = arrayfun(@(x) sprintf("%0.3f",x), T);
%T(isSig) = arrayfun(@(x) sprintf("\\textbf{%s}",x), T(isSig));
T(isSig) = sprintf("$<$%0.2f", alpha);

for iAA = 1:length(AlgoAccs), AA = AlgoAccs(iAA);
    %for iBK = 1:length(BalanceKernels), BK = BalanceKernels(iBK);
    T0 = squeeze(T(:,:,iAA));
    PrintRow(fID, T0, BalanceKernels, AA);
    %end
end

PrintFooter(fID);

end

%==========================================================================
function p = GetLCPValue(X1, AA)
AA = extract(AA, ("AUC"|"accuracy"|"precision"|"recall"|"specificity"|"F1Score"));
X = X1.parameters.multilevel.Mres(:);
Y = X1.results.(AA);
lm = fitlm(X,Y);
p = lm.Coefficients.pValue(2);
%p = lm.Coefficients
end
%==========================================================================
function p = GetVPValue(X1, AA)
AA = extract(AA, ("AUC"|"accuracy"|"precision"|"recall"|"specificity"|"F1Score"));
Y = X1.results.(AA);
[~,p,~,~] = vartest(Y, 0.0001);
end
%==========================================================================
function [DataSets, DataAliases] = CreateDataLabels

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

end
%==========================================================================

function fID = GetfID(p)
TablePath = fullfile('..',p.Results,p.MOE, p.CrossVal, 'Tables');
if ~isfolder(TablePath), mkdir(TablePath), end
path = fullfile(TablePath, 'Linear_Coefficient_PValue.txt');
fID = fopen(path, "w+");
edit(path);
end

%==========================================================================

function X = GetFiles(p)
    
    folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.DS, p.HoldOut,'**', '*.mat');
    X = dir(folderpath); 

    Balance = extract(p.BK, ("Balanced"| "Unbalanced"));
    Kernel = extract(p.BK, ("Linear"|"Radial"));
    Algo = extract(p.AA, ("MLS"|"ACA-L"|"ACA-S"));

    %if contains(AA, "ACA-L"), keyboard, end

    idx = contains({X.folder}, Balance) & ...
        contains({X.name}, Kernel) & ...
        contains({X.name}, Algo) & ...
        contains({X.name}, p.Normalized) & ...
        contains({X.name}, "Eigen-" + p.Trunc);
    X = X(idx);

    if length(X) ~= 1, keyboard, end

    X = load(fullfile(X.folder, X.name));

end

%==========================================================================
function PrintHeader(fID, DataAliases)

%Print Table "preamble"
fprintf(fID, ['\\begin{tiny}\n' ...
    '\\begin{longtable}[c]\n',... 
    ]);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.3em}",[1 x])), [1 2 3 3]);
columnstr(1) = "C{4.8em}";
columnstr = "|" + strjoin(columnstr,"|") + "|";

fprintf(fID, '{%s}\n',columnstr);
fprintf(fID, '\\hline \n \\rowcolor{olive!40}\n');
fprintf(fID, ['Regime & \\multicolumn{2}{|c|}{Genetic}'...
    '& \\multicolumn{3}{|c|}{Proteomic (ADNI)} '...
    '& \\multicolumn{3}{|c|}{CSF}\\\\ \n']);
fprintf(fID, '\\hline \n\n \\rowcolor{gray!20} \n\n');

%print actual datasets
pattern = ("ADNI "| "CSF "| "("| ")");
DataAliases = arrayfun(@(x) replace(x,pattern, ''), DataAliases);

fprintf(fID, '& %s ', DataAliases);
fprintf(fID, ' \\\\ \n \\hline');
end
%==========================================================================

function PrintRow(fID, T, BK, AA)


Algo = extract(AA, ("MLS "|"ACA-L "|"ACA-S "));
Metric = extract(AA, ("AUC"|"accuracy"|"precision"|"recall"|"specificity"|"F1Score"));
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
space = @(str) replace(str, "F1Score", "F1 Score");
fix = @(str) space(capitalize(str));
Metric = fix(Metric);

AA = Algo + Metric;

%Print Subtable Header
BK = replace(BK, "Radial", "RBF");
%AA = replace(AA, "accuracy", "Accuracy");
AA = fix(AA);
fprintf(fID, [' \\hline' ...
    '\\rowcolor{gray!40}' ...
    '\\multicolumn{%d}{|c|}{%s}' ...
    '\\\\ \n \\hline '], ...
    width(T) + 1, AA);

%T = arrayfun(@(x) sprintf("%0.3f",x), T);

fprintf(fID, '\n \\hline \n\n');
for i = 1:size(T,1)
if mod(i,2) == 1, fprintf(fID, '\\rowcolor{blue!20}\n'); end

fprintf(fID, '%s', BK(i));
fprintf(fID, ' & %s', T(i,:));
fprintf(fID, '\\\\ \n');
    
end

fprintf(fID, '\\hline ');

end

%==========================================================================
function PrintFooter(fID)
fprintf(fID, '\\caption{}\n');
fprintf(fID, '\\label{Linear_Coefficient_PValue_Table}\n');
fprintf(fID, '\\end{longtable} \n');
fprintf(fID, '\\end{tiny}')
end
%==========================================================================