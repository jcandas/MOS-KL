function CreateAblationTables

%% Example
% \begin{tabular}{|c|c|c|}
%     tits &  
%     \multicolumn{2}{c|}{pussies} \\
%     \hline
%     tits & pussies & cocks
% \end{tabular}

Datasets = ["Plasma_M12_ADCN", "Plasma_M12_ADLMCI", "Plasma_M12_CNLMCI",...
            "GCM", "newAD","SOMAscan7k_KNNimputed_AD_CN"];
Accs = ["AUC", "accuracy"];
Colors = ["blue!20", "teal!30"];
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);

filepath = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Kfold', 'Tables');
fileID = fopen(fullfile(filepath, 'Ablations.tex'), 'w');

%% Write the header for the ablation tables
fprintf(fileID, ['\\begin{table} [h] \n'...
    '\\centering \n'...
    '\\begin{tabular}{|c|c|c|c|c|c|c|} \n'...
    '\\hline \n'...
    '\\rowcolor{olive!40} \n'...
    '\\hline \n']);

fprintf(fileID, ['Ablation &'...
    '\\multicolumn{6}{c|}{Datasets} \\\\ \n'...
    '\\hline \\hline \n']);

fprintf(fileID, ['\\rowcolor{gray!90} \n' ...
    '&' ...
    '\\multicolumn{3}{c|}{ADNI} \n' ...
    '& GCM & newAD & CSF \\\\ \n' ]);

fprintf(fileID, ['& AD vs. CN & '...
    'AD vs. LMCI & '...
    'CN vs. LMCI & '...
    ' &  & '...
    '\n \\\\ \\hline  \n']);

for Acc = Accs
    Color = Colors(Accs == Acc);



fprintf(fileID, ['\\hline \\rowcolor{gray!40} \n' ...
    '    \\multicolumn{7}{|c|}{%s}' ...
    '\n \\\\ \\hline \\hline \n'], Acc);


%% Load in the data
AblationMatrix = [];
for dataset = Datasets
    filepath = fullfile('..', 'results', 'Manual_Hyperparameter_Selection',...
        'Kfold', dataset, 'Leave_1_out', 'Unbalanced');
    filename = sprintf('%s-Ablations-Normalized.mat', dataset);
    

    load(fullfile(filepath, filename));
    AblationList = parameters.Ablation.List;
    newColumn = results.(Acc)';
    

    filename = sprintf('%s-Benchmark-Normalized.mat', dataset);
    load(fullfile(filepath, filename));

    newColumn = [ results.(Acc)(parameters.misc.MachineList == "SVM_Linear") ;
                  results.(Acc)(parameters.misc.MachineList == "SVM_Radial") ;
                  newColumn]; 
        
    AblationMatrix = [AblationMatrix,  newColumn ];
    
end

Ablations = ["SVM w/ linear",...
            "SVM w/ RBF",...
            AblationList];


for iab = 1:length(Ablations)
    Ablation = Ablations(iab);

    if mod(iab, 2) == 1, fprintf(fileID, '\\rowcolor{%s} \n', Color); end

    fprintf(fileID, '%s ', Ablation);
    fprintf(fileID, ' & %0.3f', AblationMatrix(iab,:));
    fprintf(fileID, '\\\\ \n');
end


fprintf(fileID, '\\hline \n \n \n ');

end

fprintf(fileID, ['\\hline \n'...
'\\end{tabular} \n'...
'\\caption{ } \n' ...
'\\label{Ablations Appendix} \n'...
'\\end{table} \n']);




% fprintf(fileID, ['&' ...
%     ''])



end