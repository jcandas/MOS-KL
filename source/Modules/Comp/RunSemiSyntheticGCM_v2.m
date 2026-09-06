function RunSemiSyntheticGCM_v2(SinOv, ArsOv, BrsOv)
% RunSemiSyntheticGCM_v2  Second semisynthetic GCM sweep (no plots), a variant of
% RunSemiSyntheticGCM with four changes; the previous results are NOT touched.
%
%   1. Per-SAMPLE normalization (the previous scheme), applied globally:
%        - generation input in snapshotsgendata  (parameters.data.normPerSample=true)
%        - the per-fold model input in SplitTraining5
%          (methods.all.normalizedata = @MyUnitVarianceSample instead of
%           the per-feature @MyUnitVariance2, which is kept intact).
%   2. MLP / ResNet-3 / ResNet-30 standardize per feature INTERNALLY
%        (parameters.nn.standardize = true) in both the MLS and benchmark paths.
%   3. More unbalanced sizes: Ars=[150 450 1500 10000 50000 100000], Brs=100 each.
%   4. Output goes to a SEPARATE results root (results_semisyn_v2), so the earlier
%        semisynthetic results are preserved.
%
%   GCM, SVM linear, k1=39, validationType='Synthetic', sin(omega*x) for omega in
%   {15,18,20}, NKLTerms=89, NTest=10000 held out per class. Serial (Synthetic
%   requires parallel off).
%
%   Run from the Comp folder:
%     cd /project/deeprca/FINDER-ML/source/Modules/Comp
%     addpath(genpath('/project/deeprca/FINDER-ML/source'))
%     RunSemiSyntheticGCM_v2

methods = DefineMethods;
% Use snapshotsgendata (applies sin itself, reads NKLTerms) instead of the default
% GaussianGenData; no-op corruptData so readData3 does not apply sin a SECOND time.
methods.Multi.generateData = @snapshotsgendata;
methods.all.corruptData    = @(Datas, parameters, methods) deal(Datas, parameters);
% Change 1b: per-SAMPLE fold normalization (previous scheme); MyUnitVariance2 kept.
methods.all.normalizedata  = @MyUnitVarianceSample;
% Change 2 (benchmark path): NNs standardize per feature internally.
methods.misc.MLP      = @(X,Y) ConstructMLP(X, Y, struct('nn', struct('standardize', true)));
methods.misc.ResNet3  = @(X,Y) ConstructResNet(X, Y, struct('nn', struct('resBlocks', 3,  'width', 64, 'maxEpochs', 30, 'standardize', true)));
methods.misc.ResNet30 = @(X,Y) ConstructResNet(X, Y, struct('nn', struct('resBlocks', 30, 'width', 64, 'maxEpochs', 30, 'standardize', true)));

Sin  = [15 18 20];
Ars  = [150 450 1500 10000 50000];             % change 3 (100000 dropped: too heavy to schedule)
Brs  = [100 100 100  100   100];
NTest = 10000;
% Optional overrides (for smoke tests): RunSemiSyntheticGCM_v2(15,[150 450],[100 100])
if nargin >= 1 && ~isempty(SinOv), Sin = SinOv; end
if nargin >= 2 && ~isempty(ArsOv), Ars = ArsOv; end
if nargin >= 3 && ~isempty(BrsOv), Brs = BrsOv; end
% splitTraining reserves the first Brs class-A samples for SVM training and the
% rest for the covariance/filter subset; Ars<=Brs => empty covariance set => hang.
assert(all(Ars > Brs), 'Every Ars must exceed the matching Brs (splitTraining).');

delete(gcp('nocreate'));
base = methods.all.initialization();
delete(gcp('nocreate'));            % Synthetic must run serial (filefunc3 asserts parallel.on==0)
base.parallel.on = false;

% ---- v2 toggles carried on the parameters struct ----
base.data.normPerSample = true;                                       % change 1a
base.data.resultsRoot   = fullfile(getenv('PNAS_ROOT'), 'results_semisyn_v2');  % change 4
base.nn.standardize     = true;                                       % change 2 (MLS path)

for omega = Sin
    for svmonly = [1 0]             % 1 = Benchmark, 0 = MLS
        fprintf('[RunSemiSyntheticGCM_v2] sin=%d  svmonly=%d\n', omega, svmonly);
        runSynthConfig(methods, base, omega, Ars, Brs, NTest, svmonly);
    end
end
fprintf('[RunSemiSyntheticGCM_v2] done.\n');
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
% re-affirm v2 toggles in case GetCommonParameters reset parameters.data fields
parameters.data.normPerSample = true;
parameters.data.resultsRoot   = base.data.resultsRoot;

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
