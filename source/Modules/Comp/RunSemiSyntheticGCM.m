function RunSemiSyntheticGCM()
% RunSemiSyntheticGCM  Semisynthetic GCM runs (no plots).
%
%   GCM, SVM linear, k1=39, validationType='Synthetic', generated with
%   snapshotsgendata under the sin transform sin(omega*x) for omega in {15,18,20},
%   NKLTerms=89. Sample sizes Ars=[150 450 1500 10000] (Tumor), Brs=[100 100 100
%   100] (Normal), NTest=10000 held out per class. Full model set
%   (SVM/MLP/ResNet-3/ResNet-30) in both the MLS and benchmark paths.
%   Mres_auto='MLS', chooseTrunc=false. Serial (Synthetic requires parallel off).
%
%   Run from the Comp folder:
%     cd /project/deeprca/FINDER-ML/source/Modules/Comp
%     addpath(genpath('/project/deeprca/FINDER-ML/source'))
%     RunSemiSyntheticGCM

methods = DefineMethods;
% Use snapshotsgendata (applies sin itself, reads NKLTerms) instead of the default
% GaussianGenData; no-op corruptData so readData3 does not apply sin a SECOND time.
methods.Multi.generateData = @snapshotsgendata;
methods.all.corruptData    = @(Datas, parameters, methods) deal(Datas, parameters);

Sin  = [15 18 20];
Ars  = [150 450 1500 10000];
Brs  = [100 100 100 100];
NTest = 10000;
% splitTraining reserves the first Brs class-A samples for SVM training and the
% rest for the covariance/filter subset; Ars<=Brs => empty covariance set => hang.
assert(all(Ars > Brs), 'Every Ars must exceed the matching Brs (splitTraining).');

delete(gcp('nocreate'));
base = methods.all.initialization();
delete(gcp('nocreate'));            % Synthetic must run serial (filefunc3 asserts parallel.on==0)
base.parallel.on = false;

for omega = Sin
    for svmonly = [1 0]             % 1 = Benchmark, 0 = MLS
        fprintf('[RunSemiSyntheticGCM] sin=%d  svmonly=%d\n', omega, svmonly);
        runSynthConfig(methods, base, omega, Ars, Brs, NTest, svmonly);
    end
end
fprintf('[RunSemiSyntheticGCM] done.\n');
end

% ------------------------------------------------------------------
function runSynthConfig(methods, base, omega, Ars, Brs, NTest, svmonly)
parameters = base;
parameters.data.label            = 'GCM';
parameters.data.name             = 'GCM.txt';
parameters.data.validationType   = 'Synthetic';
parameters.svm.kernal            = false;               % linear
parameters.multilevel.svmonly    = svmonly;
parameters.multilevel.splitTraining = (svmonly == 0);
parameters.multilevel.l          = 'max';
parameters.multilevel.Mres_auto  = 'MLS';
parameters.multilevel.chooseTrunc = false;

parameters.synthetic.functionTransform   = omega;       % snapshotsgendata -> sin(omega*x)
parameters.synthetic.GaussianNoiseFactor = [];
parameters.synthetic.NKLTerms            = 89;
parameters.synthetic.Ars                 = Ars;
parameters.synthetic.Brs                 = Brs;
parameters.synthetic.NTest               = NTest;

% sets data.path (Tan_data-2/), snapshots.k1=39, nominal/anomalous for GCM
parameters = methods.data.GetCommonParameters(parameters, methods);
parameters.data.nk = numel(Ars);

for k = 1:parameters.data.nk
    parameters.data.currentiter = k;
    [Datas, parameters] = methods.all.readcancerData(parameters, methods);   % snapshotsgendata + sin
    parameters = methods.all.GetMaxMultiLevel(Datas, parameters, methods);
    results    = methods.all.iniresults(parameters);
    parameters = methods.all.Datasize(Datas, parameters);
    [Datas]    = methods.all.selectgene(Datas, parameters.data.numofgene, parameters.data.B);

    switch svmonly
        case 1, results = methods.SVMonly.CompSVMonly(methods, Datas, parameters, results);
        case 0, results = methods.Multi.CompMulti(methods, Datas, parameters, results);
    end
    results = methods.all.ComputeAccuracyAndPrecision(Datas, parameters, methods, results);

    parameters = methods.all.filefunc(parameters, methods);
    Datas.rawdata.AData = []; Datas.rawdata.BData = [];
    save(fullfile(parameters.datafolder, parameters.dataname), 'parameters', 'results', 'Datas');
end
end
