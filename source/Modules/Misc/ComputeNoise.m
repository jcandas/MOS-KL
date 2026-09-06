function ComputeNoise

Datasets = [...
              "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscan7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            "GCM"...
            ];

% myload = @(x) load(fullfile(x.folder, x.name));
% 
% thisdir = pwd;
methods = DefineMethods;
methods.all.initialization = @InitializeParameters4;

% D = methods.all.ValuesTable(...
%                             'Balance', {true, false},...
%                             'Kernel', {true, false},...
%                             'Eigenspace', {'smallest', 'largest'},...
%                             'ChooseTrunc', {false},...
%                             'Name', cellstr(Datasets),...
%                             'PCA', {true},...
%                             'Algorithm', {1,2,0});


% resultsFolders = ["Manual_Hyperparameter_Selection"];
% CV = ["Kfold"];
% Balances = ["Balanced", "Unbalanced"];

ClassANoise = nan(size(Datasets));
ClassBNoise = ClassANoise;
for DS = Datasets(:)'
fprintf('Processing %s \n', DS);
parameters = methods.all.initialization();
parameters.data.label = char(DS);
parameters.data.name = [char(DS) '.txt'];
parameters = methods.data.GetCommonParameters(parameters, methods);
[Datas, parameters] = methods.all.readcancerData(parameters, methods);
parameters = methods.all.Datasize(Datas, parameters);

ClassANoiseDS = ComputeNoiseSub(Datas, parameters, 'A');
ClassBNoiseDS = ComputeNoiseSub(Datas, parameters, 'B');

iDS = Datasets == DS;
ClassANoise(iDS) = mean(ClassANoiseDS);
ClassBNoise(iDS) = mean(ClassBNoiseDS);

end

T = table(ClassANoise, ClassBNoise); 
T.Properties.RowNames = Datasets;
disp(T);

end


function noise = ComputeNoiseSub(Datas, parameters, C)

N = parameters.data.(C);
noise = nan(N,1);
X = Datas.rawdata.([C 'Data']);
X = X - mean(X,2);
Cov = 1/(N-1)*(X*X');

for i = 1:length(noise)
    X0 = X; X0(:,i) = [];
    X0 = X0 - mean(X0,2);
    Cov0 = 1/(N-2)*(X0*X0');
    noise(i) = norm(Cov0 - Cov, 'fro') / norm(Cov0, 'fro');
end

end





% 
% blankRows = [];
% for irow = 1:height(D)
% parameters =  methods.all.initialization();
% parameters.multilevel.splitTraining = D.Balance(irow); 
% parameters.svm.kernal = D.Kernel(irow); 
% parameters.multilevel.eigentag = D.Eigenspace{irow}; 
% parameters.multilevel.svmonly = D.Algorithm(irow); 
% parameters.multilevel.chooseTrunc = D.ChooseTrunc(irow);

% 
% parameters = methods.all.filefunc(parameters);
% irowFile = fullfile(parameters.datafolder, parameters.dataname);
% if ~isfile(irowFile)
%     blankRows = [blankRows irow];
% end
% 
% end





