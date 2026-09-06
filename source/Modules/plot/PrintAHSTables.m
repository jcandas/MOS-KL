function PrintAHSTables
rF = 'results2';

TablePath = fullfile('..', rF, 'Manual_Hyperparameter_Selection', 'Kfold');
load(fullfile(TablePath, 'Graphs', 'Algorithmic_Hyperparameter_Selection.mat'));
fileID = fopen(fullfile(TablePath, 'Tables', 'AHS_Table.tex'), "w+");

%Print Table
PrintTable(fileID, T);
PrintFigures(rF, T);

end

%==========================================================================
function PrintHeader(fileID, T)

columnstr = repmat("",[1 width(T)+2]);
columnstr([3 7]) = "|";
columnstr(columnstr == "") = "C{3.9em}";
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

%print actual Data Aliases
Machines = string(T.Properties.VariableNames);
pattern = ("ADNI "| "CSF "| "("| ")");
Machines = arrayfun(@(x) replace(x,pattern, ''), Machines);

fprintf(fileID,  '\\rowcolor{gray!20} \n  ');
fprintf(fileID, '& %s ', Machines);
fprintf(fileID, ' \\\\ \n \\hline');
end
%==========================================================================
function PrintAccuracyRow(fileID, Acc, T)
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

fprintf(fileID, ['\n \\hline' ...
    '\\rowcolor{gray!40}' ...
    '\\multicolumn{%d}{|c|}{%s}' ...
    '\\\\ \\hline \\hline \n \n'], ...
    width(T) + 1, capitalize(Acc));
end
%==========================================================================
function [Metrics, Codes] = GetTextData(T)

Algos = ["MLS", "ACA-S", "ACA-L"];
RN = ["I", "II", "III", "IV"];
A2 = ["Bench", "Metric"];
A3 = [Algos, A2];

Metrics = nan(length(Algos)+2, width(T));
Codes = repmat("", size(Metrics));

DAs = string(T.Properties.VariableNames);
for DA = DAs

    %Get FINDER Data
    for Algo = Algos
       X1 = cellfun( @(x) x{1}(Algos == Algo), T.(DA));
       X2 = cellfun( @(x) x{2}(Algos == Algo), T.(DA));
       [X3, i3] = max(X1);
       X4 = X2(i3); X4 = replace(X4, Algo + " ", "");

       Metrics(A3 == Algo, DAs == DA) = X3;
       Codes(A3 == Algo, DAs == DA) = RN(i3) + " (" + X4 + ")";
    end

    
       Metrics(A3 == "Bench", DAs == DA) = T.(DA){1}{3}.Bench;
       Codes(A3 == "Bench", DAs == DA) = BenchmarkDictionary(T.(DA){1}{3}.Classifier);

       Metrics(A3 == "Metric", DAs == DA) = T.(DA){1}{3}.Metric;
       Codes(A3 == "Metric", DAs == DA) = T.(DA){1}{3}.Finder + "-" + ...
           T.(DA){1}{3}.Balanced + T.(DA){1}{3}.Kernel;

end

end
%==========================================================================
function Bout = BenchmarkDictionary(Bin)


Machines = ["SVM_Linear-PCA", "SVM_Radial-PCA",...
    "SVM_Linear", "SVM_Radial",...
    "LogitBoost", "RUSBoost", "Bag"];

%if ~ismember(Bin, Machines), keyboard, end
Aliases = ["L-PCA", "R-PCA",...
            "SVM-L", "SVM-R",...
            "Log", "RUS", "Bag"];

if ismember(Bin, Machines)
Bout = Aliases(Machines == Bin);
elseif ismember(Bin, Aliases)
Bout = Machines(Aliases == Bin);
else 
    keyboard
end 

end
%==========================================================================
function PrintRow(fileID, Metrics, Codes)

Algos = ["MLS", "ACA-S", "ACA-L"];
RN = ["I", "II", "III", "IV"];
A2 = ["Benchmark", "Manual"];
A3 = [Algos, A2];

for Algo = A3
    fprintf(fileID, '\\rowcolor{blue!20} \n');
    fprintf(fileID, '%s', Algo);
    MetricRow = Metrics(A3 == Algo,:);
    for iDA = 1:length(MetricRow)
        MetricCol = Metrics(:,iDA);
        maxMetric = max(MetricCol);
        Metric = MetricRow(iDA);
        switch Metric == maxMetric
            case true
                fprintf(fileID, ' & \\textbf{%0.3f}', Metric);
            case false
                fprintf(fileID, ' & %0.3f', Metric);
        end
    end

    
    fprintf(fileID, ' \\\\ \n');
    fprintf(fileID, ' & %s', Codes(A3 == Algo,:));
    fprintf(fileID, ' \\\\ \n \n');
end

end
%==========================================================================
function PrintTable(fileID, T)
PrintHeader(fileID, T.AUC);
for Acc = ["AUC", "accuracy"]
    PrintAccuracyRow(fileID, Acc, T.(Acc));
    [Metrics, Codes] = GetTextData(T.(Acc));
    PrintRow(fileID, Metrics, Codes)
    fprintf(fileID, '\\hline \n \n');
end

fclose(fileID);
end
%==========================================================================
function PrintFigures(rF, T)

textwidthprop = 0.8;
methods = DefineMethods;
TablePath = fullfile('..', rF, 'Manual_Hyperparameter_Selection', 'Kfold', 'Tables');

AFID = fopen(fullfile(TablePath, 'AHS_ADNI_graphs.tex'), "w+");
GFID = fopen(fullfile(TablePath, 'AHS_Genetic_graphs.tex'), "w+");
CFID = fopen(fullfile(TablePath, 'AHS_CSF_graphs.tex'), "w+");


   % [Metrics, Codes] = GetTextData(T.(Acc));
DataAliases = string(T.AUC.Properties.VariableNames);
for DA = DataAliases
    
if ismember(DA, ["GCM", "newAD"])
    FID = GFID; 
elseif ismember(DA, methods.data.ADNI_files)
    FID = AFID;
elseif ismember(DA, methods.data.CSF_files)
    FID = CFID;
end

captionstring = PrintCaptionString(T, DA);
Args = {textwidthprop, DA, captionstring, DA};
fprintf(FID, [ ...
    '\\begin{figure}[h} \n' ...
    '\\includegraphics[width = %0.1f\\textwidth]' ...
    '{Algorithmic_Hyperparameter_Selection/AHS_%s.pdf} \n' ...
    '\\caption{%s} \n' ...
    '\\label{AHS_%s}'], ...
    Args{:});

fprintf(FID,'\n\n\n');


    %for Acc = ["AUC", "accuracy"]
    %end
    
end

fclose all;

end
%==========================================================================
function str = PrintCaptionString(T, DA)

Algos = ["MLS", "ACA-S", "ACA-L"];
Accs = ["AUC", "accuracy"];
%CodePattern = ("I"|"II"|"III"|"IV"|"U"|"B"|"L"|"R");
CodePattern = ("U"|"B"|"L"|"R");
%RN = ["I", "II", "III", "IV"];
abbvstr = ["U" "B" "L" "R"]; %, RN];
longstr = ["Unbalanced", "Balanced", "Linear SVM", "RBF SVM"]; %,...
            %arrayfun(@(x) sprintf("Auto-%s",x),RN)];
myreplace = @(str) replace(str, abbvstr, longstr);

strs = ["", ""];
for Acc = Accs
icolumn =  string(T.(Acc).Properties.VariableNames) == DA;
[Metrics, Codes] = GetTextData(T.(Acc));

MetricCol = Metrics(:,icolumn); CodeCol = Codes(:,icolumn);
[Metric, imax] = max(MetricCol); Code = CodeCol(imax);

if ismember(imax, [1 2 3])
    str = extract(Code, CodePattern)';
    str = myreplace(str); %replace(str, abbvstr, longstr);
    str = [Algos(imax), ...
        "Auto-" + extractBefore(Code, " (") , ...
        str];
    str = strjoin(str, ", ");
elseif imax == 4
    str = BenchmarkDictionary(Code);
elseif imax == 5
    str = [T.(DA){1}{3}.Finder,...
           myreplace(T.(DA){1}{3}.Balanced),...
           myreplace(T.(DA){1}{3}.Kernel)];
end

end



end
