function [parameters] = InitializeParameters()

%% Data parameters
% data.path is set per-dataset by GetCommonParameters (relative to PNAS_ROOT).
parameters.data.path = '';
parameters.data.label = 'GCM';
%'Plasma_M12_ADCN';

parameters.data.name = [parameters.data.label, '.txt'];

parameters.data.validationType = 'Kfold';  %One of 'Synthetic', 'Kfold', or 'Cross'
parameters.data.numofgene = []; % Set to empty array [] to initialize as latent data dimension
parameters.data.normalize = true; % if 1 then Data standarized
parameters.data.randomize = true; % true = randomly permute data upon loading
parameters.data.nominal = 'Normal';
parameters.data.anomalous = 'Tumor';

%% Cross Validation Parameters
parameters.cross.NTestA = 1;
parameters.cross.NTestB = 1;


%% K-fold parameters
parameters.Kfold = 10; %If parameters.data.generealization is set to 1,


%% Semi-synthetic data realization parameters
parameters.synthetic.functionTransform = []; %if 'id';
parameters.synthetic.GaussianNoiseFactor = [];
parameters.synthetic.NKLTerms = 88; % KL Truncation for generating Semisynthetic Data
parameters.synthetic.Ars = [600];
parameters.synthetic.Brs = [200];
parameters.synthetic.NTest = 10000;


%% MultiLevel parameters
parameters.snapshots.k1 = 5;% KL Truncation for Class A
parameters.multilevel.svmonly = 0; % 0 = MLS, 1 = Benchmark, 2 = ACA
parameters.multilevel.splitTraining = true; % true = Balanced, false = Unbalanced
parameters.multilevel.eigentag = 'smallest'; %'largest' = ACA-L, 'smallest' = ACA-S
parameters.multilevel.Mres_manual = [];
parameters.multilevel.Mres_auto = 'MLS';
%parameters.multilevel.Mres = unique([parameters.multilevel.Mres_manual(:),...
 %                             parameters.multilevel.Mres_auto(:)]);

parameters.multilevel.l = 0; % number of multilevel subspaces for MLS method (set to max if unsure)
parameters.multilevel.nested = 1; % if 0 then non nested, if 1 nesting is 0-l, if 2 nesting is l-max(l), 

parameters.multilevel.chooseTrunc = false; %manual vs algorithmic MA and Mres selection (still in beta).
parameters.multilevel.concentration = 0.95; %algorithmic parameter selection parameter

%% MLS classifiers (fitted per level, side-by-side) + NN settings
parameters.multilevel.Classifiers = ["SVM", "MLP", "ResNet3", "ResNet30"];
parameters.multilevel.currentClassifier = "SVM"; % set per-iteration by the comp loop
parameters.nn.mlpLayers = [64 32 16];
parameters.nn.resBlocks  = 3;
parameters.nn.width      = 64;
parameters.nn.maxEpochs  = 30;

%% Baseline performance parameters
parameters.misc.MachineList = ["SVM_Linear-PCA", "SVM_Radial-PCA", "SVM_Linear", "SVM_Radial", "LogitBoost", "RUSBoost", "Bag", "MLP", "ResNet3", "ResNet30"]; %Benchmark learners
%["SVM_Linear-PCA", 
parameters.misc.PCA = [];

%% Ablation List
parameters.Ablation.List = ["2nd degree polynomial kernel",... Use polynomial kernel of order 2
                            "Kernel scaling",... Set Kernel Scaling to 1
                            "L1 quadratic programming solver",...Use L1 Quadrating Programming Solver as the optimization routine
                            ..."10-fold cross validation",...
                            ..."5-fold cross validation",...set Number of folds to 5
                            "Box constraint = 10",...
                            "Standardized",... set to true
                            "Delta gradient tolerance = $10^{-2}$"]; ... Stop convergence early


%% Assorted parameters
parameters.parallel.on = true; %true; %true = use parallel toolbox
parameters.svm.kernal = false;% true = use RBF for SVM separating surface (FINDER only)
parameters.gpuarray.on = false; % true = convert all data arrays to GPU arrays. 
parameters.snapshots.controlRand = false;

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


% Open a parallel pool only if requested AND the Parallel Computing Toolbox is
% available; otherwise fall back to serial so the code runs without the toolbox.
if parameters.parallel.on == 1
    if license('test', 'Distrib_Computing_Toolbox') && ~isempty(ver('parallel'))
        parameters.parallel.numofproc = maxNumCompThreads;
        if isempty(gcp('nocreate'))
            parpool(parameters.parallel.numofproc);
        end
    else
        warning('Parallel Computing Toolbox not available -- running serially.');
        parameters.parallel.on = 0;
    end
end






