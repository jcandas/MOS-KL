function WriteSemiSyntheticLatexMarkup

SSpath = fullfile('..', 'results',...
    'Manual_Hyperparameter_Selection',...
    'Synthetic', 'Graphs');
SSfolderList = dir(fullfile(SSpath, '*.pdf'));

fileID = fopen(fullfile(SSpath, 'Synthetic_Graphs.txt'), 'w+');
SSfolderList(matches({SSfolderList.name}, [".", ".."])) = [];

for i = 1:length(SSfolderList)

graphics = SSfolderList(i).name;
[l, Balance, Acc] = extractFilenameProperties(graphics);
l = LabelDictionary(l);
caption = sprintf('%s for %s data %s', Acc, l, Balance);
label = extractBefore(graphics, '.pdf');

fprintf(fileID, '\\begin{figure}[h] \n');
fprintf(fileID, '\\centering \n');
fprintf(fileID, '\\includegraphics[width=\\linewidth]{%s} \n', ...
    fullfile('Synthetic_Graphs', graphics));
fprintf(fileID, '\\caption{%s} \n', caption);
fprintf(fileID, '\\label{%s} \n', label);
fprintf(fileID, '\\end{figure} \n');
fprintf(fileID, '\n\n\n');
end
end

function [label, Balance, Acc] = extractFilenameProperties(filename)

switch contains(filename, 'Balanced')
    case true, Balance = "with pre-balancing";
                B = "Balanced";
    case false, Balance = "without pre-balancing";
                B = "Unbalanced";
end

switch contains(filename, 'AUC')
    case true, Acc = "AUC";
                A = "AUC";
    case false, Acc = "Accuracy";  
                A = "accuracy";
end

str = sprintf('_%s', [B, A, 'Synthetic.pdf']);
label = extractBefore(filename, str);

properties = {label, Balance, Acc};

end

function out = LabelDictionary(label)

narginchk(0,1)

LD = ["GCM", "GCM";
    "newAD", "newAD";
    "Plasma_M12_ADCN", "ADNI (AD vs. CN)";
    "Plasma_M12_ADLMCI", "ADNI (AD vs. LMCI)";
    "Plasma_M12_CNLMCI", "ADNI (CN vs. LMCI)";
    "SOMAscan7k_KNNimputed_CN_EMCI", "CSF (CN vs. EMCI)";
    "SOMAscan7k_KNNimputed_AD_CN", "CSF (AD vs. CN)";
    ];

switch nargin
    case 0
        out = LD;
    case 1
        if ismember(label, LD(:,1))
            out = LD(LD(:,1) == string(label), 2);
        elseif ismember(label, LD(:,2))
            out = LD(LD(:,2) == string(label), 1);
        else
            error('label not found in dictionary')
        end
end

end