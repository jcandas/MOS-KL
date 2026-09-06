function [parameters] = InitializeParameters3()

%% Data parameters
parameters.data.path = '';
%'/restricted/projectnb/sctad/Audrey/SOMAscan7k_KNNimputed_formatted_data/'; %'/restricted/projectnb/sctad/Codes/Yumeng/'; % % %'/restricted/projectnb/sctad/Audrey/ADNI_2024_Audrey/CSF_dataset/'; %
parameters.data.label = 'Plasma_M12_ADLMCI'; %'SOMAscan7k_KNNimputed_CN_EMCI'; %'ionosphere'; %'2024_CNEMCI_lasso_45'; %'Plasma_M12_ADLMCI'; %'GCM'; %'CSF_PET_Classification'; %
parameters.data.name = [parameters.data.label, '.txt'];
parameters.data.numofgene = []; % Set to empty array [] to initialize as latent data dimension
parameters.data.normalize = true; % if 1 then standarized
parameters.data.validationType = 'Synthetic'; %One of 'Kfold', 'Cross', or 'Synthetic'
parameters.data.randomize = true;

%% Cross Validation Parameters
parameters.cross.NTestA = 1;
parameters.cross.NTestB = 1;

%% K-fold parameters
parameters.Kfold = 5; %If parameters.data.generealization is set to 1,


%% Semi-synthetic data realization parameters
parameters.synthetic.functionTransform = []; %if 'id';
parameters.synthetic.NKLTerms = 54; % KL Truncation for generating Semisynthetic Data
parameters.synthetic.Ars = 600;
parameters.synthetic.Brs = 200;
parameters.synthetic.NTest = 10000;


%% MultiLevel parameters
parameters.snapshots.k1 = 5; % KL Truncation for Class A
parameters.multilevel.chooseTrunc = false;
parameters.multilevel.l = 'max'; % level for classifier (was 8)
parameters.multilevel.nested = 1; % if 0 then non nested, if 1 nesting is 0-l, if 2 nesting is l-max(l), 
parameters.multilevel.svmonly = 2; % if 1 then SVM only, if 0 then multilevel, if 2 then Trajan's Multilevel, 
parameters.multilevel.splitTraining = true; %if True, then Training A data is split into ML-filter subset and SVM training subset
parameters.multilevel.eigentag = 'smallest'; %if 'largest', uses principal eigenspace, if 'smallest' uses terminal eigenspace
parameters.multilevel.concentration = 0.95;
%parameters.multilevel.Mres = 'MLS';
parameters.multilevel.Mres_manual = []; %200:200:2000;
parameters.multilevel.Mres_auto = 'MLS';

%% Baseline performance parameters
parameters.misc.MachineList = ["SVM_Linear-PCA", "SVM_Radial-PCA", "SVM_Linear", "SVM_Radial", "LogitBoost", "RUSBoost", "Bag"];
parameters.misc.PCA = true;

%% Assorted parameters
parameters.parallel.on = false; % if 1 then use parloop 
parameters.svm.kernal = false; % if 1 then use SVM with kernal, else use linear boundary 
parameters.snapshots.controlRand = false;
parameters.gpuarray.on = false;% iftr1 then convert all arrays to GPU arrays. 

%% Transform Parameters (can mostly ignore)
parameters.transform.ComputeTransform = false;
parameters.transform.createPlots = false; 
% parameters.transform.RankTol = 10^-6;
% parameters.transform.alpha = 0.05;
% parameters.transform.beta = 0.05;
% parameters.transform.optimoptions = {'fmincon',...
%                                     ...'DerivativeCheck', 'on',...
%                                     ...'Algorithm', 'active-set',...
%                                     'Display', 'none',...
%                                     'MaxFunctionEvaluations', 10^5,...
%                                     'EnableFeasibilityMode', true,...
%                                     ...'HessianApproximation', 'lbfgs',...
%                                     'SpecifyObjectiveGradient', true, ...
%                                     'SpecifyConstraintGradient', true,...
%                                     'UseParallel', true,...
%                                     'StepTolerance', 10^(-10),...
%                                     'FunctionTolerance', 10^(-6),...
%                                     'MaxIterations', 500};
% parameters.transform.useHessian = true;
% parameters.transform.dimTransformedSpace = 60; %Initialize to empty to default to min(Ntrainingsamples, NFeatures);








if strcmp(parameters.data.validationType, 'Synthetic')
    parameters.data.nk = size(parameters.synthetic.Brs, 2); % num of simulations 
    assert(length(parameters.synthetic.Brs) == length(parameters.synthetic.Ars),...
        'parameters.snapshots.Ars and parameters.snapshots.Brs must have the same number of elements')
else 
    parameters.data.nk = 1;
end


if parameters.parallel.on == 1
    %Initialize Parallel
    parameters.parallel.numofproc = maxNumCompThreads;
    parpool(parameters.parallel.numofproc);
    %parpool(12);
end







end
