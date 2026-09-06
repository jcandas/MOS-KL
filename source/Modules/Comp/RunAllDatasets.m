function RunAllDatasets(whichFamily)
% RunAllDatasets  Run standard datasets through the benchmark and MLS pipelines
% and save the result .mat files. No plots.
%
%   RunAllDatasets              % all four families
%   RunAllDatasets('ADNI')      % one family (ADNI|CSF|newAD|GCM) -- for parallel jobs
%
%   Datasets (all Kfold=10, all labels per family, full model set
%   SVM/MLP/ResNet-3/ResNet-30 in both the MLS and benchmark paths):
%     ADNI  - SVM radial, k1=5  (Plasma_M12_ADCN/ADLMCI/CNLMCI)
%     CSF   - SVM linear, k1=8  (6 SOMAscan7k pairs)
%     newAD - SVM linear, k1=8
%     GCM   - SVM linear, k1=39
%
%   k1 is set per dataset by GetCommonParameters; Mres_auto='MLS' and
%   chooseTrunc=false throughout (the InitializeParameters defaults). Each
%   (label, algorithm) result is written via filefunc3.
%
%   Run from the Comp folder:
%     cd /project/deeprca/FINDER-ML/source/Modules/Comp
%     addpath(genpath('/project/deeprca/FINDER-ML/source'))
%     RunAllDatasets

if nargin < 1, whichFamily = ""; end
whichFamily = string(whichFamily);

methods = DefineMethods;

% {name, labels, kernal}: ADNI radial (kernal=true), the rest linear (kernal=false)
families = { "ADNI",  methods.data.ADNI_files, true; ...
             "CSF",   methods.data.CSF_files,  false; ...
             "newAD", {'newAD'},               false; ...
             "GCM",   {'GCM'},                 false };

if strlength(whichFamily) > 0
    keep = strcmpi(string(families(:,1)), whichFamily);
    assert(any(keep), 'Unknown family "%s" (ADNI|CSF|newAD|GCM)', whichFamily);
    families = families(keep, :);
end

delete(gcp('nocreate'));
base = methods.all.initialization();   % one parallel pool for all configs

for f = 1:size(families, 1)
    labels = families{f,2};
    kernal = families{f,3};
    for li = 1:numel(labels)
        for svmonly = [1 0]            % 1 = Benchmark, 0 = MLS
            fprintf('[RunAllDatasets] %s  kernal=%d  svmonly=%d\n', labels{li}, kernal, svmonly);
            runOneConfig(methods, base, labels{li}, kernal, svmonly);
        end
    end
end

delete(gcp('nocreate'));
fprintf('[RunAllDatasets] done.\n');
end

% ------------------------------------------------------------------
function runOneConfig(methods, base, label, kernal, svmonly)
parameters = base;
parameters.data.label            = label;
parameters.data.name             = [label '.txt'];
parameters.data.validationType   = 'Kfold';
parameters.Kfold                 = 10;
parameters.svm.kernal            = kernal;
parameters.multilevel.svmonly    = svmonly;
parameters.multilevel.splitTraining = (svmonly == 0);   % MLS balanced, Benchmark unbalanced
parameters.multilevel.l          = 'max';               % sweep all MLS eigen-levels
parameters.multilevel.Mres_auto  = 'MLS';
parameters.multilevel.chooseTrunc = false;

% sets data.path, snapshots.k1 (5/8/39) and nominal/anomalous per label
parameters = methods.data.GetCommonParameters(parameters, methods);
parameters.data.nk = 1;
parameters.data.currentiter = 1;

[Datas, parameters] = methods.all.readcancerData(parameters, methods);
parameters = methods.all.GetMaxMultiLevel(Datas, parameters, methods);
results    = methods.all.iniresults(parameters);
parameters = methods.all.Datasize(Datas, parameters);
[Datas]    = methods.all.selectgene(Datas, parameters.data.numofgene, parameters.data.B);

switch svmonly
    case 1, results = methods.SVMonly.CompSVMonly(methods, Datas, parameters, results);   % benchmark
    case 0, results = methods.Multi.CompMulti(methods, Datas, parameters, results);       % MLS
end
results = methods.all.ComputeAccuracyAndPrecision(Datas, parameters, methods, results);

parameters = methods.all.filefunc(parameters, methods);
Datas.rawdata.AData = []; Datas.rawdata.BData = [];
save(fullfile(parameters.datafolder, parameters.dataname), 'parameters', 'results', 'Datas');
end
