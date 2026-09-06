function WriteHoldoutPairedTestTables
close all

rF = 'results';
nesting = 'Inner-Nesting';
p.alpha = 0.01;
p.DSidx = [1:8];


p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitBox";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";
p.FontSize = "tiny";
p.TableName = "Balance_Kernel_Friedmans_Test";


%% Create Table 1
Factors = {"Algos"};
for i = 1:length(Factors)
p.Factor = Factors{i}; 
p = CreateDataLabels(p);
p = FillArray(p);
p = GetfID(p);
PrintHeader(p);
PrintBody(p);
PrintFooter(p);
end

%% Trick Table by flipping Balance Kernels and Algos
% Algos = p.Algos;
% BalanceKernels = p.BalanceKernels;
% p.Algos = BalanceKernels; p.BalanceKernels = Algos;
% p.pValues = nan(length(p.Accs), length(p.DS), length(p.BalanceKernels));
% p.TableName = "FINDER_Friednamns_Test";
% p = FillArray(p);
% p = GetfID(p);
% PrintHeader(p);
% PrintBody(p);
% PrintFooter(p);

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
p.isProteomic = ismember(p.DS, p.DS(3:5));
p.isCSF = ismember(p.DS, p.DS(6:8));
p.Sources = ["Genetic", "Proteomic", "CSF"];
fields = ["DS", "DA", "is" + p.Sources, "Truncs"];
for field = fields
    p.(field) = p.(field)(p.DSidx);
end

p.Balances = ["Balanced", "Unbalanced"];
p.Kernels = ["Linear", "Radial"];
p.Algos = ["MLS", "ACA-L", "ACA-S"]; 

PossibleFactors = ["Balances", "Kernels", "Algos"];
p.AntiFactor = PossibleFactors(~ismember(PossibleFactors, p.Factor));

for field = ["Factor", "AntiFactor"]
    fieldLevel = field + "Level";
    fieldInput = arrayfun(@(f) p.(f), p.(field), 'UniformOutput', false);
    fieldOutput = cell(size(p.(field)));
    [fieldOutput{:}] = ndgrid(fieldInput{:});
    fun = @(i) [fieldOutput{i}(:)];
    fieldOutput = arrayfun(fun, 1:length(fieldOutput), 'UniformOutput', false);
    fieldOutput = [fieldOutput{:}];
    p.(fieldLevel) = fieldOutput;

end

p.Accs = ["recall", "specificity", "accuracy", "precision", "AUC", "F1Score"];

p.pValues = nan(length(p.Accs), length(p.DS), length(p.AntiFactorLevel));

switch size(p.FactorLevel,2) == 2
    case true, statName = "Wilcoxon";
    case false, statName = "Friedman";
end

p.TableName = strjoin([p.Factor, statName, "Test"], "_");

end

%===========================================================================
function p = FillArray(p)
fprintf('Obtaining Performance Metrics\n');

for iDS = 1:length(p.DS)
    p.ds = p.DS(iDS); 
    p.da = p.DA(iDS);
    p.Trunc = p.Truncs(iDS);
    fprintf("\t Processing %s\n", p.ds);

for iAnt = 1:size(p.AntiFactorLevel,1)

    p.AF = p.AntiFactorLevel(iAnt,:);
    X0 = GetPaths(p);
    X1 = load(X0{1});
    [A,B] = meshgrid(X1.parameters.data.NAvals, ...
                     X1.parameters.data.NBvals);
    pairs = [A(:), B(:)];
    
for iAcc = 1:length(p.Accs)
    Acc = p.Accs(iAcc);
    Array = nan(size(pairs,1), size(p.FactorLevel,1));

for iFac = 1:size(p.FactorLevel,1)
    p.Fac = p.FactorLevel(iFac,:);

    idx = true(size(X0));
    for f = p.Fac, idx = idx & contains(X0, f); end
    if sum(idx) ~= 1, keyboard, end

    X2 = X0{idx};
    X3 = load(X2);
    [~,iLevel] = max(X3.results.(Acc));

for ipair = 1:size(pairs,1)
    iA = pairs(ipair,1); iB = pairs(ipair,2);
    results.array = X3.results.array(iA,iB,iLevel,:,:);
    results = ComputeResultsAUC(results);
    results = ComputeResultsAccuracy(results);
    Array(ipair, iFac) = results.(Acc);
    if isnan(results.(Acc)), keyboard, end
end, end



if size(Array,2) == 2
    statsfun = @(A) signrank(A(:,1), A(:,2), Tail = "both");
else
    reps = max(X3.parameters.data.NAvals);
    statsfun = @(A) friedman(A, reps, "off");
end

x = any(isnan(Array(:))); if x, keyboard, end

p.pValues(iAcc, iDS, iAnt) = statsfun(Array);
end, end,end

end
%==========================================================================
function X = GetPaths(p)

folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.ds, p.HoldOut,'**', '*.mat');
X = dir(folderpath); 
Paths = fullfile({X.folder}, {X.name}); 

idx = contains(Paths, p.Normalized)...
    & contains(Paths, "Eigen-" + p.Trunc);


for af = p.AF
    idx = idx & contains(Paths, af);
end

X = Paths(idx);
%X = arrayfun(@(x) load(fullfile(x.folder, x.name)), X);

end
%==========================================================================
function p = GetfID(p)
p.TableFolder = fullfile("..",p.Results,p.MOE, p.CrossVal, "Tables");

if ~isfolder(p.TableFolder), mkdir(p.TableFolder), end
path = fullfile(p.TableFolder, p.TableName + ".txt");
p.fID = fopen(path, "w+");
edit(path);
end
%==========================================================================
function PrintHeader(p)

%% Print Table "preamble"
fprintf(p.fID, "\\begin{%s}\n", p.FontSize);
fprintf(p.fID, '\\begin{longtable}[c]\n');

nDS = arrayfun(@(f) sum(p.("is" + f)), p.Sources);

columnstr = arrayfun(@(x) strjoin(repmat("C{2.3em}",[1 x])), [1 nDS]);
columnstr(1) = "C{4.8em}";
columnstr = "|" + strjoin(columnstr,"|") + "|";

fprintf(p.fID, '{%s}\n',columnstr);
fprintf(p.fID, '\\hline \n \\rowcolor{olive!40}\n Metric');

for i = 1:length(p.Sources)
fprintf(p.fID, " & \\multicolumn{%d}{|c|}{%s}", nDS(i), p.Sources(i));
end
fprintf(p.fID, '\\\\ \\hline \n\n \\rowcolor{gray!20} \n\n');

%% print actual datasets
pattern = ("ADNI "| "CSF "| "("| ")");
DataAliases = arrayfun(@(x) replace(x,pattern, ''), p.DA);

fprintf(p.fID, "& %s ", DataAliases);
fprintf(p.fID, " \\\\ \n \\hline");
end

%==========================================================================
function PrintBody(p)
for iAnt = 1:size(p.AntiFactorLevel,1)
    p.iAnt = iAnt;
    RowHeader = strjoin(p.AntiFactorLevel(iAnt,:), ", ");
    %% Print Row Header;
    fprintf(p.fID, "\\hline " + ...
        "\\rowcolor{gray!40}" + ...
        "\\multicolumn{%d}{|c|}{%s}" + ...
        "\\\\ \n \\hline ", ...
        size(p.pValues,2) + 1, RowHeader);
    
    PrintData(p);
end
end
%==========================================================================
function PrintData(p)

pValues = p.pValues(:,:,p.iAnt);
isSig = pValues < p.alpha;
pValues = arrayfun(@(x) sprintf("%0.3f",x), pValues);
pValues(isSig) = sprintf("$<$%0.2f", p.alpha);

capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
Accs = p.Accs;
Accs = replace(Accs, "F1Score", "F1 Score");
Accs = capitalize(Accs);

fprintf(p.fID, "\\hline \n");
for iA = 1:length(Accs)
    if mod(iA,2) == 1
    fprintf(p.fID, "\\rowcolor{blue!20} \n");
    end
    fprintf(p.fID, Accs(iA));
    fprintf(p.fID, " & %s ", pValues(iA,:));
    fprintf(p.fID, "\\\\ \n");
end
fprintf(p.fID, " \\hline\n");

end
%==========================================================================
function PrintFooter(p)
fprintf(p.fID, '\\caption{}\n');
fprintf(p.fID, "\\label{%s}\n", p.TableName);
fprintf(p.fID, '\\end{longtable} \n');
fprintf(p.fID, "\\end{%s}", p.FontSize);
end
%==========================================================================