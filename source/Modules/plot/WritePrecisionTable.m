function WritePrecisionTable
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

[DataSets, DataAliases] = CreateDataLabels();

Balances = ["Balanced", "Unbalanced"];
Kernels = ["Linear", "Radial"];
[Balances, Kernels] = meshgrid(Balances, Kernels);
BalanceKernels = Balances(:) + ", " + Kernels(:);

Algos = ["MLS", "ACA-S", "ACA-L"];

T = nan(length(Algos), length(DataSets), length(BalanceKernels));

for iDS = 1:length(DataSets)
    DS = DataSets(iDS); DA = DataAliases(iDS);
    p.DS = DS; p.Trunc = p.Truncs(iDS);

    fprintf('Processing %s \n', DA);
for iBK = 1:length(BalanceKernels), BK = BalanceKernels(iBK);
    p.BK = BK;
for iAlgo = 1:length(Algos), Algo = Algos(iAlgo);
    p.Algo = Algo; 

    X1 = GetFiles(p);
    T(iAlgo, iDS, iBK) = max(X1.results.recall);
end
end
end

fID = GetfID(p);
PrintHeader(fID, DataAliases);

for iBK = 1:length(BalanceKernels), BK = BalanceKernels(iBK);
    PrintRow(fID, T(:,:,iBK), Algos, BK);
end

PrintFooter(fID);

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
TablePath = fullfile('..',p.Results, p.MOE, p.CrossVal, 'Tables');
if ~isfolder(TablePath), mkdir(TablePath), end
fID = fopen(fullfile(TablePath, 'Precision_Table.txt'), "w+");
end

%==========================================================================

function X = GetFiles(p)
    
   
    folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.DS, p.HoldOut,'**', '*.mat');
    X = dir(folderpath); 

    Balance = extract(p.BK, ("Balanced"| "Unbalanced"));
    Kernel = extract(p.BK, ("Linear"|"Radial"));

    idx = contains({X.folder}, Balance) & ...
        contains({X.name}, Kernel) & ...
        contains({X.name}, p.Algo) & ...
        contains({X.name}, "Eigen-" + p.Trunc) & ...
        contains({X.name}, p.Normalized);
    X = X(idx);

    if length(X) ~= 1, keyboard, end

    X = load(fullfile(X.folder, X.name));

end

%==========================================================================
function PrintHeader(fID, DataAliases)

%Print Table "preamble"
fprintf(fID, ['\\begin{table} [H]\n',... 
'\\centering\n',...
'\\footnotesize\n']);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.6em}",[1 x])), [1 2 3 3]);
columnstr(1) = "C{4.2em}";
columnstr = "|" + strjoin(columnstr,"|") + "|";

fprintf(fID, '\\begin{tabular}\n {%s}\n',columnstr);
fprintf(fID, '\\hline \n \\rowcolor{olive!40}\n');
fprintf(fID, ['Method & \\multicolumn{2}{|c|}{Genetic}'...
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

function PrintRow(fID, T, Algos, BK)

%Print Subtable Header
BK = replace(BK, "Radial", "RBF");
fprintf(fID, [' \\hline' ...
    '\\rowcolor{gray!40}' ...
    '\\multicolumn{%d}{|c|}{%s}' ...
    '\\\\ \n \\hline '], ...
    width(T) + 1, BK);

%T = arrayfun(@(x) sprintf("%0.3f",x), T);

fprintf(fID, '\\hline \n\n');
for i = 1:size(T,1)
if mod(i,2) == 1, fprintf(fID, '\\rowcolor{blue!20}\n'); end

fprintf(fID, '%s', Algos(i));
fprintf(fID, ' & %0.3f', T(i,:));
fprintf(fID, '\\\\ \n');
    
end

fprintf(fID, '\\hline ');

end

%==========================================================================
function PrintFooter(fID)
fprintf(fID, '\n\n \\end{tabular}\n');
fprintf(fID, '\\caption{}\n');
fprintf(fID, '\\label{Precision_Table}\n');
fprintf(fID, '\\end{table}');
end
%==========================================================================