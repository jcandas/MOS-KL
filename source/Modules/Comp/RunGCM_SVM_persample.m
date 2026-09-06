function RunGCM_SVM_persample(k1, kernal, Kf, svmonlyList)
% k1 defaults to 20; pass 39 to keep the original GCM filter dimension and thereby
% isolate the normalization effect (per-sample vs per-feature at the same k1).
% kernal defaults to false (linear); pass true for the RBF (radial) kernel. Radial
% runs go to a separate ..._radial results root (the benchmark filename is
% kernel-agnostic, so it would otherwise overwrite the linear one).
% RunGCM_SVM_persample  Standard (non-synthetic) GCM re-run to test whether
% per-sample normalization + k1=20 changes the SVM results, vs the existing GCM
% run (per-feature normalization, k1=39). Only SVM is fitted, in BOTH paths:
%   - SVM + MLS  (multilevel, balanced)   -> GCM-MLS-...-Eigen-20-MyUnitVarianceSample
%   - SVM  Orig  (benchmark, linear SVM)  -> GCM-Benchmark-MyUnitVarianceSample
%
% Setup: GCM, leave-10-pairs-out (Kfold=10), linear kernel, k1=20, PER-SAMPLE
% normalization (MyUnitVarianceSample). Output goes to a SEPARATE root
% (results_gcm_svm_k20/) so the main results/ tree is untouched.
%
%   cd /project/deeprca/FINDER-ML/source/Modules/Comp
%   addpath(genpath('/project/deeprca/FINDER-ML/source'))
%   RunGCM_SVM_persample

if nargin < 1 || isempty(k1), k1 = 20; end
if nargin < 2 || isempty(kernal), kernal = false; end
if nargin < 3 || isempty(Kf), Kf = 10; end          % leave-Kf-pairs-out
if nargin < 4 || isempty(svmonlyList), svmonlyList = [1 0]; end  % 1=Benchmark, 0=MLS

methods = DefineMethods;
methods.all.normalizedata = @MyUnitVarianceSample;    % per-sample normalization

delete(gcp('nocreate'));
base = methods.all.initialization();
if kernal, ksuf = '_radial'; else, ksuf = ''; end
base.data.resultsRoot       = fullfile(getenv('PNAS_ROOT'), sprintf('results_gcm_svm_k%d%s', k1, ksuf));
base.snapshots.k1           = k1;
base.Kfold                  = Kf;                     % leave-Kf-pairs-out
base.parallel.on            = true;                   % explicit: use parfor over folds
base.svm.kernal             = kernal;                 % false=linear, true=RBF/radial
base.multilevel.Classifiers = "SVM";                  % MLS path: SVM only
if kernal, base.misc.MachineList = "SVM_Radial"; else, base.misc.MachineList = "SVM_Linear"; end

for svmonly = svmonlyList        % 1 = Benchmark (SVM Orig), 0 = MLS (SVM+MLS)
    fprintf('[RunGCM_SVM_persample] k1=%d  kernal=%d  svmonly=%d\n', k1, kernal, svmonly);
    runOne(methods, base, svmonly);
end
delete(gcp('nocreate'));
fprintf('[RunGCM_SVM_persample] done.\n');
end

% ------------------------------------------------------------------
function runOne(methods, base, svmonly)
parameters = base;
parameters.data.label            = 'GCM';
parameters.data.name             = 'GCM.txt';
parameters.data.validationType   = 'Kfold';
parameters.Kfold                 = base.Kfold;
parameters.svm.kernal            = base.svm.kernal;   % false=linear, true=radial
parameters.multilevel.svmonly    = svmonly;
parameters.multilevel.splitTraining = (svmonly == 0);
parameters.multilevel.l          = 'max';
parameters.multilevel.Mres_auto  = 'MLS';
parameters.multilevel.chooseTrunc = false;

parameters = methods.data.GetCommonParameters(parameters, methods);  % sets k1=39 for GCM
parameters.snapshots.k1          = base.snapshots.k1; % <-- k1 override (20 or 39)
parameters.data.resultsRoot      = base.data.resultsRoot;
parameters.multilevel.Classifiers = "SVM";
parameters.misc.MachineList       = base.misc.MachineList;
parameters.data.nk = 1;
parameters.data.currentiter = 1;

[Datas, parameters] = methods.all.readcancerData(parameters, methods);
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
