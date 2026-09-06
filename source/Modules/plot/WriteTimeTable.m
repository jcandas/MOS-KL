function WriteTimeTable
close all
DSidx = [1:5, 6,8,10];

TablePath = fullfile('..','results2','Manual_Hyperparameter_Selection', 'Kfold', 'Tables');
if ~isfolder(TablePath), mkdir(TablePath); end

GeneticDS = ["GCM", "newAD"]; 
ADNIDS =    arrayfun(@(x) sprintf("Plasma_M12_%s",x),... 
            ["ADCN", "ADLMCI", "CNLMCI"]);
CSFDS =     arrayfun(@(x) sprintf("SOMAscan7k_KNNimputed_%s", x),...
            ["AD_CN", "AD_EMCI", "AD_LMCI", "CN_EMCI", "CN_LMCI", "EMCI_LMCI"]);

DataSets = [GeneticDS, ADNIDS, CSFDS];

GeneticDA = ["GCM", "newAD"];
ADNIDA =    ["AD vs. CN", "AD vs. LMCI", "CN vs. LMCI"];
CSFDA =      ["AD vs. CN" , "AD vs. EMCI", "AD vs. LMCI", "CN vs. EMCI", "CN vs. LMCI", "EMCI vs. LMCI"];

DataAliases = [GeneticDA, ADNIDA, CSFDA];

root = getenv('PNAS_ROOT');
DataPaths = [string(fullfile(root,'data','Tan_data-2'));
    string(fullfile(root,'data','newAD'));
    string(fullfile(root,'data','ADNI_data'));
    string(fullfile(root,'data','CSF_data'))];

Breaks = [1,3,6];
Truncations = [39,8,5,8];

DataSets = DataSets(DSidx); DataAliases = DataAliases(DSidx);



methods = DefineMethods;



%% Write the header for the ablation tables


Headers = {"MLS-Lin", "MLS-RBF",...
    "ACA-L-Lin", "ACA-L-RBF", "ACA-S-Lin", "ACA-S-RBF",...
    "SVM_Linear", "SVM_Radial", "SVM_Linear_PCA", "SVM_Radial_PCA", ...
"LogitBoost", "RUSBoost", "Bag"};

NMachines = length(Headers);
NTakes = 8;
Run_Times = nan(length(DataSets), NMachines, NTakes);
% = {};

%DataSets = DataSets(1);

%load(fullfile(TablePath, 'RunTimeData.mat'));
for iDS = 1:length(DataSets)


    DS = DataSets(iDS);
    DA = DataAliases(iDS);
    fprintf('Processing %s \n', DA);

    % if DS == "GCM", j = 1;        
    % elseif DS == "newAD", j = 2;        
    % elseif ismember(DS, DataSets(3:5)), j = 3;      
    % elseif ismember(DS, DataSets(6:end)), j = 4;
    % end
    % 
    % parameters.data.path = DataPaths(j);
    parameters = InitializeParameters4();
    %parameters.misc.MachineList = ["SVM_Linear-PCA", "SVM_Radial-PCA"];
    %parameters.misc.MachineList(contains(parameters.misc.MachineList, "PCA")) = [];
    parameters.data.label = DS;
    parameters.data.name = DS + ".txt";
    parameters = methods.data.GetCommonParameters(parameters, methods);
    [Datas,parameters] = methods.all.readcancerData(parameters, methods);
    parameters = methods.all.Datasize(Datas, parameters);
    parameters = methods.all.GetMaxMultiLevel(Datas, parameters, methods);
    parameters.data.i = 1; parameters.data.j = 1;
    Datas = methods.all.prepdata(Datas, parameters);
    %parameters.snapshots.k1 = Truncations(j);
    

for iM = 1:NMachines %9:10 %
    fprintf('\t %s.', Headers{iM});
    
    if contains(Headers{iM}, "MLS")%ismember(iM, [1 2])
        parameters.multilevel.svmonly = 0;
    elseif contains(Headers{iM}, "ACA") %ismember(iM, 3:6)
        parameters.multilevel.svmonly = 2;
    else%if ismember(iM, 7:length(Headers))
        parameters.multilevel.svmonly = 1;
    end

    % if contains(Headers{iM}, "Lin") %ismember(iM, [1 3 5])
    %     parameters.svm.kernal = false;
    % elseif contains(Headers{iM}, "RBF") %ismember(iM, [2 4 6])
    %     parameters.svm.kernal = true;
    % end

    parameters.svm.kernal = contains(Headers{iM}, "RBF");

    
for iT = 1:NTakes
    %% MLS

    % w/o kernel
    % w/ kernel

    t0 = tic; 
    if contains(Headers{iM}, "MLS") %ismember(iM, [1 2])
        %l = ceil(parameters.multilevel.l / 2);
        l = parameters.multilevel.l;
        Datas2 = methods.all.prepdata(Datas, parameters);
        t1 = toc(t0);
        [Datas2, parameters2] = methods.Multi.Filter(Datas2, parameters, methods);
        [Datas2, parameters2] = methods.Multi.machine(Datas2, parameters2, methods,l);
    elseif contains(Headers{iM}, "ACA") %ismember(iM, 3:6)
        t1 = toc(t0);
        Datas2 = methods.Multi2.ConstructResidualSubspace(Datas, parameters, methods);
        %parameters2.multilevel.iMres = floor(parameters2.data.numofgene * 0.5);
        parameters2.multilevel.iMres = parameters2.multilevel.Mres_auto(end);
        Datas2 = methods.Multi2.SepFilter(Datas2, parameters2, methods); %Apply Filter 
        Datas2 = methods.SVMonly.Prep(Datas2); %Prepare Training and Testing Data for SVM
        parameters2 = methods.SVMonly.fitSVM(Datas2, parameters2, methods); %Construct SVM 
    else %if ismember(iM, 7:length(Headers))
        %iMachine = iM - 6;
        parameters2 = parameters;
        machine = Headers{iM};%parameters.misc.MachineList(iMachine);
        parameters2.misc.PCA = contains(machine, "PCA");
        machine = replace(machine, "_PCA", "");
        Datas2 = methods.all.prepdata(Datas, parameters2);
        t1 = toc(t0);
       
        [Datas2, parameters2] = methods.misc.PCA(Datas2, parameters2, methods);
         Datas2 = methods.misc.prep(Datas2, parameters2); 
        parameters2.multilevel.SVMModel = methods.misc.(machine)(Datas2.X_Train, Datas2.y_Train);
    end
    methods.all.predict(Datas2, parameters2, methods);
    t2 = toc(t0);

    Run_Times(iDS, iM, iT) = t2 - t1;
    

   
    Datas2 = Datas;
    parameters2 = parameters;

    %% ACA 

    %L w/0 kernel
    %L w/ kernel
    %S w/0 kernel
    %S w/ kernel

    %% Benchmarks
end
rt = squeeze(Run_Times(iDS, iM, :));
rt = mean(rt(2:end));
fprintf(' Elapsed Time: %0.2f s\n', rt);


% pg = squeeze(Run_Times(iDS, iM, :));
% if any(isnan(pg))
%     keyboard
% end
    


end

    
    
    

end

%Run_Times(:,:,1) = [];
Run_Times = trimmean(Run_Times, 20, 3);
%Run_Times = mean(Run_Times, 3);
    % Run_TimesC = cell(size(Run_Times) + [1 1]);
    % Run_TimesC(1,2:end) = Headers;
    % Run_Times(2:end,1) = cellstr(DataSets');
    % Run_TimesC(2:end, 2:end) = num2cell(Run_Times);

    save(fullfile(TablePath, 'RunTimeData.mat'),...
        'Run_Times', 'Headers', 'DataSets', 'DataAliases');

    fprintf('All Done! \n')



