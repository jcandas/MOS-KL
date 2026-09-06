function LPOCVTruncations

%% Initialize Datas, parameters, methods
methods = DefineMethods;
parameters = InitializeParameters;
parameters.multilevel.chooseTrunc = true;
DS = [{'GCM', 'newAD'},...
     methods.data.ADNI_files,...     
     methods.data.CSF_files([1 3 5]),...
      ];
MOEs = arrayfun( @(x) str2func(sprintf("MethodOfEllipsoids_%d", x)), ...
    8:11, 'UniformOutput', false);
Accs = ["AUC", "accuracy"];
Balances = ["Unbalanced", "Balanced"];
svmonlys = [0 2];

eigentags = ["smallest", "largest"];
D = methods.all.ValuesTable(...
                            'Balance', {false,true},...
                            'Kernel', {false,true},...
                            'Eigenspace', {'largest', 'smallest'},...
                            'Algorithm', {2,0}, ...
                            'MOE', MOEs,...
                            'Name', DS ...
                            );


load '..'/results/Manual_Hyperparameter_Selection/Graphs/Best.mat;
warning('off', 'all')


for iDS = 1:length(DataAliases)%irowLPOCV = 195:height(D)
    DataSet = DS{iDS};
    %DataAlias = DataAliases(iDS);
    %if mod(irowLPOCV,10) == 0 || irowLPOCV == 1 || irowLPOCV == height(D)
    fprintf('Processing %s (%d of %d)\n', DataSet, iDS, length(DataAliases));
    %end
    close all

for iAcc = 1:length(Accs)
     Acc = Accs(iAcc);

     %% Get Best parameters for this data set and assign them to the parameters struct
     column = Table(:,iDS,iAcc);
     FINDER1 = column(RowNames == "FINDER1");
     isRBF = column(RowNames == "Kernel1") == "RBF";
     isBalanced = contains(FINDER1, "*");
     eigentag = char(eigentags(contains(FINDER1, "-L") + 1));
     svmonly = svmonlys(contains(FINDER1, "ACA") + 1);

 
     parameters.data.label = DataSet; %D.Name{irowLPOCV};
     parameters.data.name = [parameters.data.label, '.txt'];
     parameters.multilevel.splitTraining = isBalanced; %D.Balance(irowLPOCV); %D{irowkNN,1};
     parameters.svm.kernal = isRBF; %D.Kernel(irowLPOCV); %D{irowkNN,2};
     parameters.multilevel.eigentag = eigentag; %D.Eigenspace{irowLPOCV}; % D{irowkNN,3};
     parameters.multilevel.svmonly = svmonly; %D.Algorithm(irowLPOCV); %D{irowkNN,4};
 
 for iMOE = 1:length(MOEs)
     MOE = MOEs{iMOE};
     MOEstr = func2str(MOE);
     fprintf('\t Processing %s\n', MOEstr);
    methods.Multi2.ChooseTruncations = MOE; %D.MOE{irowLPOCV};

    %% See if the file already exists
    parameters = methods.all.filefunc(parameters, methods);
    X = dir(fullfile('..','Truncations', MOEstr, 'Kfold', ...
        DataSet, 'Leave_1_out', Balances(isBalanced+1)));
    matchPattern = extractBefore(parameters.dataname, '-Eigen');
    isMatch = any(contains({X.name}, matchPattern));
    if isMatch, continue, end
    % filePath = replace(parameters.datafolder, 'results','Truncations');
    % fileName = fullfile(filePath, parameters.dataname);
    % if isfile(fileName), continue, end
    LPOCVTruncationsSub(parameters, methods);
    %save('irowLPOCV.mat', 'irowLPOCV');
 end

end

end

end

function LPOCVTruncationsSub(parameters, methods)


[Datas, parameters] = methods.all.readcancerData(parameters, methods);     
parameters = methods.all.Datasize(Datas, parameters);
parameters = methods.all.filefunc(parameters, methods);
Datas = methods.all.selectgene(Datas, parameters.data.numofgene, parameters.data.B);

Truncations = nan(length(parameters.data.NAvals),...
                  length(parameters.data.NBvals),...
                  2);

%% Obtain MA and Mres for each round of LPOCV
parfor i = parameters.data.NAvals
    parameters2 = parameters;
    parameters2.data.i = i;
    Tj = Truncations(i,:,:);

for j = parameters.data.NBvals
    parameters2.data.j = j;
    Datas2 = methods.all.prepdata(Datas, parameters2);% Split data into two groups: training and testing             
    parameters3 = methods.Multi2.ChooseTruncations(Datas2, parameters2, methods);
    Tj(:,j,1) = parameters3.snapshots.k1;
    Tj(:,j,2) = parameters3.multilevel.Mres;
end
    Truncations(i,:,:) = Tj;
end


%% Calculate statistics
MA = squeeze(Truncations(:,:,1)); MA = MA(:); uMA = unique(MA);
Mres = squeeze(Truncations(:,:,2)); Mres = Mres(:);
filePath = replace(parameters.datafolder, 'results','Truncations');
if ~isfolder(filePath), mkdir(filePath), end
save(fullfile(filePath, parameters.dataname), 'MA', 'Mres');

%% Load completed results
% X = dir(parameters.datafolder);
% X = X(3:end);
% resultFolders = {X.folder};
% resultNames = {X.name};
% for i = 1:length(resultNames)
%     resultDir = fullfile(resultFolders{i}, resultNames{i});
% 
%     Y = load(resultDir);
%     if Y.parameters.multilevel.svmonly == parameters.multilevel.svmonly % && ...
%         %  strcmp(Y.parameters.multilevel.eigentag, parameters.multilevel.eigentag)
% 
%     Y.results.MA = MA(:);
%     Y.results.Mres = Mres(:);
%     save(resultDir, '-struct', 'Y');
%     end
% 
% end

%% Make plots
% figure()
% subplot(2,2,1)
% hist(MA), title('MA')
% set(gca, 'XTick', uMA)
% 
% subplot(2,2,2)
% hist(Mres), title('Mres')
% 
% subplot(2,2,3)
% scatter(MA, Mres), xlabel('MA'), ylabel('Mres'), title('MA vs Mres');
% set(gca,'XTick', uMA)
% hold on
% BestMA = mode(MA);
% for u = uMA'
%     iMA = MA == u;
%     iMres = mode(Mres(iMA));
%     switch u == BestMA
%         case true, col = [1, 0.85, 0];
%         case false, col = [1, 0.5, 0];
%     end 
%     scatter(u, iMres, [], col, 'filled')
% end
% hold off

 

end