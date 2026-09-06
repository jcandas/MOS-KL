function RunSemiSynGCM_SVMradial(SinOv)
% RunSemiSynGCM_SVMradial  Semisynthetic GCM, PER-SAMPLE normalization, SVM RADIAL,
% SVM-ONLY (both MLS and benchmark paths). Same generation/normalization as
% RunSemiSyntheticGCM_v2 but with the RBF kernel and only SVM fitted -- the kernel
% affects only SVM, so the NN/baseline columns from the linear v2 run carry over
% unchanged and are not recomputed here.
%
%   Sizes Ars=[150 450 1500 10000 50000], Brs=100, NTest=10000, sin(omega*x) for
%   omega in {15,18,20}, NKLTerms=89, k1=39. Output -> results_semisyn_v2_radial/.
%   Serial (Synthetic requires parallel off).
%
%   Pass ONE sin to run a single omega per job (submit 15/18/20 in parallel):
%     RunSemiSynGCM_SVMradial(15)
%   With no argument it runs all three sequentially.

methods = DefineMethods;
methods.Multi.generateData = @snapshotsgendata;                      % applies sin, reads NKLTerms
methods.all.corruptData    = @(Datas, parameters, methods) deal(Datas, parameters);
methods.all.normalizedata  = @MyUnitVarianceSample;                  % per-sample normalization

Sin  = [15 18 20];
if nargin >= 1 && ~isempty(SinOv), Sin = SinOv; end
Ars  = [150 450 1500 10000 50000];
Brs  = [100 100 100  100   100];
NTest = 10000;
assert(all(Ars > Brs), 'Every Ars must exceed the matching Brs (splitTraining).');

delete(gcp('nocreate'));
base = methods.all.initialization();
delete(gcp('nocreate'));            % Synthetic must run serial (filefunc3 asserts parallel.on==0)
base.parallel.on            = false;
base.data.normPerSample     = true;                                  % per-sample generation input
base.data.resultsRoot       = fullfile(getenv('PNAS_ROOT'), 'results_semisyn_v2_radial');
base.svm.kernal             = true;                                  % RADIAL kernel
base.multilevel.Classifiers = "SVM";                                 % MLS path: SVM only
base.misc.MachineList       = "SVM_Radial";                          % Benchmark path: radial SVM only

for omega = Sin
    for svmonly = [1 0]             % 1 = Benchmark, 0 = MLS
        fprintf('[RunSemiSynGCM_SVMradial] sin=%d  svmonly=%d\n', omega, svmonly);
        runSynthConfig(methods, base, omega, Ars, Brs, NTest, svmonly);
    end
end
fprintf('[RunSemiSynGCM_SVMradial] done (sin=%s).\n', mat2str(Sin));
end

% ------------------------------------------------------------------
function runSynthConfig(methods, base, omega, Ars, Brs, NTest, svmonly)
parameters = base;
parameters.data.label            = 'GCM';
parameters.data.name             = 'GCM.txt';
parameters.data.validationType   = 'Synthetic';
parameters.svm.kernal            = base.svm.kernal;     % radial
parameters.multilevel.svmonly    = svmonly;
parameters.multilevel.splitTraining = (svmonly == 0);
parameters.multilevel.l          = 'max';
parameters.multilevel.Mres_auto  = 'MLS';
parameters.multilevel.chooseTrunc = false;

parameters.synthetic.functionTransform   = omega;
parameters.synthetic.GaussianNoiseFactor = [];
parameters.synthetic.NKLTerms            = 89;
parameters.synthetic.Ars                 = Ars;
parameters.synthetic.Brs                 = Brs;
parameters.synthetic.NTest               = NTest;

parameters = methods.data.GetCommonParameters(parameters, methods);  % sets path, k1=39
parameters.data.nk = numel(Ars);
% re-affirm toggles in case GetCommonParameters reset parameters.data fields
parameters.data.normPerSample     = true;
parameters.data.resultsRoot       = base.data.resultsRoot;
parameters.multilevel.Classifiers = "SVM";
parameters.misc.MachineList       = "SVM_Radial";

for k = 1:parameters.data.nk
    parameters.data.currentiter = k;
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
end
