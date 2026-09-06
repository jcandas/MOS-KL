function WriteDataInfoTable

TablePath = fullfile('..','results','Manual_Hyperparameter_Selection', 'Kfold', 'Tables');
fileID1 = fopen(fullfile(TablePath,'Data_Info_Table.tex'), 'w+');

DataSets = ["GCM", "newAD" ...
            arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]),...
            arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["EMCI_LMCI", "CN_LMCI", "AD_LMCI", "AD_EMCI", "AD_CN"]) ];

DataAliases = ["GCM", "newAD" ...
               "AD vs. CN", "AD vs. LMCI", "CN vs. LMCI",...
               "EMCI vs. LMCI", "CN vs. LMCI", "AD vs. LMCI", "AD vs. EMCI", "AD vs. CN"...
               ];


root = getenv('PNAS_ROOT');
DataPaths = [string(fullfile(root,'data','Tan_data-2'));
    string(fullfile(root,'data','newAD'));
    string(fullfile(root,'data','ADNI_data'));
    string(fullfile(root,'data','CSF_data'))];

Breaks = [1,3,6];
Truncations = [39,8,5,8];

methods = DefineMethods;
parameters = methods.all.initialization();


%% Write the header for the Quick Data Lookup  tables
fprintf(fileID1, ['\\begin{table} [h] \n'...
    '\\centering \n'...
    '\\begin{tabular}{|c|c c c c c |} \n'...
    '\\hline \n'...
    '\\rowcolor{olive!40} \n'...
    '\\hline \n']);

fprintf(fileID1, ['Dataset & \n'  ...
    '$N_\\bA$ & \n'...
    '$N_\\bB$ & \n'...
    '$\\CH$ & \n'...
    'Hold Out  \n'...
    '\\\\ \n\n']);



rowCounter = 0;
for iDS = 1:length(DataSets)

    
    if ismember(iDS, Breaks), rowCounter = 0; end
    rowCounter = rowCounter + 1;

    DS = DataSets(iDS);
    DA = DataAliases(iDS);

    %Print Header rows
    switch iDS
        case 1, PrintDataRowHeader(fileID1, 'Genetic');  
        case 3, PrintDataRowHeader(fileID1, 'Proteomic');
        case 6, PrintDataRowHeader(fileID1, 'CSF');
    end

    if DS == "GCM", j = 1;
        rowColor = 'violet!30';
    elseif DS == "newAD", j = 2;
        rowColor = 'violet!30';
    elseif ismember(DS, DataSets(3:5)), j = 3;
        rowColor = 'blue!20';
    elseif ismember(DS, DataSets(6:end)), j = 4;
        rowColor = 'teal!40';
    end

    parameters.data.path = DataPaths(j);
    parameters.data.label = DS;
    parameters.data.name = DS + ".txt";
    [Datas,parameters] = methods.all.readcancerData(parameters, methods);
    parameters = methods.all.Datasize(Datas, parameters);
    %clear Datas;

    RowArgs = {DA,...
        parameters.data.A,...
        parameters.data.B,...
        parameters.data.numofgene,...
        Truncations(j),...
        ceil(parameters.data.B/10)};

    
    if mod(rowCounter, 2) == 1
        fprintf(fileID1, '\\rowcolor{%s} \n', rowColor);
    end
    
    fprintf(fileID1, ...
        '%s & %d & %d & $\\R^{%d}$ & %d & %d \\\\ \n',...
        RowArgs{:});

end

fprintf(fileID1, ['\\hline \n\n\n\n'...
'\\end{tabular} \n'...
'\\caption{ } \n' ...
'\\label{Quick Data Info} \n'...
'\\end{table} \n']);


fclose(fileID1);

%%


end

function PrintDataRowHeader(fileID, tag)
    fprintf(fileID, ['\n \\hline \\hline ' ...
        '\\rowcolor{gray!30} \n' ...
    '\\multicolumn{6}{|c|}{%s} \\\\ \n' ...
    '\\hline \\hline'], tag);
end