function R = MeasureModelTime(family, nfolds, maxEpochs)
% MeasureModelTime  Controlled single-node benchmark of model-only fit+predict
% time per classifier, on MLS vs Original features, for one dataset family.
%
%   R = MeasureModelTime('ADNI')       % all ADNI labels, 30 folds each
%   R = MeasureModelTime('GCM', 5)     % GCM, 5 folds (quick)
%
% Runs SERIALLY (no parfor) so timings are clean and comparable, with a warm-up
% fit per model (excluded) to absorb first-call dlnetwork/JIT/library overhead.
% For each of the first NFOLDS leave-pair-out folds it rebuilds two feature reps
% -- MLS (deepest level, splitTraining balanced) and Original (unbalanced, as the
% benchmark runs) -- and times fit+predict of each classifier. Averaged over folds
% AND all labels in the family. Only fit+predict is timed (feature engineering is
% excluded). Produces 11 rows: MLS/Orig x {SVM,MLP,ResNet-3,ResNet-30} + Orig-only
% {RF,GB,RUS}. Writes results/model_runtime_<family>.csv.

if nargin < 2 || isempty(nfolds), nfolds = 30; end
if nargin < 3 || isempty(maxEpochs), maxEpochs = 30; end
family = string(family);

methods = DefineMethods;
switch family
    case "ADNI",  labels = methods.data.ADNI_files; kernal = true;    % SVM radial
    case "CSF",   labels = methods.data.CSF_files;  kernal = false;   % SVM linear
    case "newAD", labels = {'newAD'};               kernal = false;
    case "GCM",   labels = {'GCM'};                 kernal = false;
    otherwise, error('family must be ADNI|CSF|newAD|GCM');
end

delete(gcp('nocreate'));
base = methods.all.initialization();
delete(gcp('nocreate'));            % drop init's pool -- benchmark runs serial
base.parallel.on = false;
base.svm.kernal  = kernal;
base.nn.resBlocks = 3; base.nn.width = 64; base.nn.maxEpochs = maxEpochs;

mlsModels  = ["SVM","MLP","ResNet3","ResNet30"];
origModels = ["SVM","MLP","ResNet3","ResNet30","RF","GB","RUS"];
% row keys for the 11 output bars (rep|model)
keys = ["MLS|SVM","MLS|MLP","MLS|ResNet3","MLS|ResNet30", ...
        "Orig|SVM","Orig|MLP","Orig|ResNet3","Orig|ResNet30","Orig|RF","Orig|GB","Orig|RUS"];
nL = numel(labels);
T = cell(nL, numel(keys));          % per-label, per-fold times: T{label, key}
nFeat = nan(nL, numel(keys));
mlsDisp = ["SVM","MLP","ResNet-3","ResNet-30"];   % display names in the acc CSV
warmed = false;

% Best-accuracy MLS level per (task, classifier), from the summarized results.
% Each MLS classifier is timed at the level that maximised ITS accuracy for the
% task (matching the accuracy tables/plots), rather than the deepest level.
accCsv = string(fullfile(getenv('PNAS_ROOT'), 'results', "acc_" + family + ".csv"));
if isfile(accCsv), accTab = readtable(accCsv, 'TextType','string'); else, accTab = []; end

for di = 1:nL
    ds = labels{di};
    p = base; p.data.label = ds; p.data.name = [ds '.txt'];
    p = methods.data.GetCommonParameters(p, methods);
    p.data.validationType = 'Kfold'; p.Kfold = 10;
    p.multilevel.l = 'max'; p.multilevel.Mres_auto = 'MLS'; p.multilevel.chooseTrunc = false;
    p.data.currentiter = 1;
    [Datas, p] = methods.all.readcancerData(p, methods);
    p = methods.all.GetMaxMultiLevel(Datas, p, methods);
    p = methods.all.Datasize(Datas, p);
    [Datas] = methods.all.selectgene(Datas, p.data.numofgene, p.data.B);
    Backup = Datas;
    l = p.multilevel.l;

    % best-accuracy level for each MLS classifier on this task (fallback: deepest)
    levk = repmat(l, 1, numel(mlsModels));
    for k = 1:numel(mlsModels)
        lv = lookupLevel(accTab, ds, mlsDisp(k));
        if ~isnan(lv), levk(k) = lv; end
    end

    [I,J] = ndgrid(p.data.NAvals, p.data.NBvals);
    pairs = [I(:) J(:)];
    nf = min(nfolds, size(pairs,1));

    for f = 1:nf
        p.data.i = pairs(f,1); p.data.j = pairs(f,2);
        % Original rep (unbalanced, as benchmark runs)
        pO = p; pO.multilevel.splitTraining = false; pO.misc.PCA = false;
        DO = methods.all.prepdata(Backup, pO, methods);
        DO = methods.misc.PCA(DO, pO, methods);
        DO = methods.misc.prep(DO);
        % MLS rep (balanced): filter once, then build each classifier's machine
        % at the level that maximised that classifier's accuracy for this task.
        pM = p; pM.multilevel.splitTraining = true;
        DMf = methods.all.prepdata(Backup, pM, methods);
        [DMf, pMf] = methods.Multi.Filter(DMf, pM, methods);

        if ~warmed   % one untimed fit per model to absorb first-call overhead
            for k = 1:numel(mlsModels)
                [DMk, pMk] = methods.Multi.machine(DMf, pMf, methods, levk(k));
                fitTime(mlsModels(k), DMk, pMk);
            end
            for m = origModels, fitTime(m, DO, pO); end
            warmed = true;
        end

        for k = 1:numel(mlsModels)                              % MLS bars
            [DMk, pMk] = methods.Multi.machine(DMf, pMf, methods, levk(k));
            [tt] = fitTime(mlsModels(k), DMk, pMk);
            T{di,k}(end+1) = tt; nFeat(di,k) = size(DMk.X_Train,2);
        end
        for k = 1:numel(origModels)                             % Original bars
            [tt] = fitTime(origModels(k), DO, pO);
            idx = 4 + k;
            T{di,idx}(end+1) = tt; nFeat(di,idx) = size(DO.X_Train,2);
        end
    end
    fprintf('[%s] %s: %d folds timed (origDim=%d, MLS levels %s dims %s)\n', ...
        family, ds, nf, nFeat(di,5), mat2str(levk), mat2str(nFeat(di,1:4)));
end

% ---- aggregate: one block of 11 rows per task, plus a pooled "ALL" block ----
disp2 = ["SVM","MLP","ResNet-3","ResNet-30","SVM","MLP","ResNet-3","ResNet-30","Random Forest","Gradient Boosting","RUS Boost"];
reps  = ["MLS","MLS","MLS","MLS","Orig","Orig","Orig","Orig","Orig","Orig","Orig"];
Family=strings(0); Task=strings(0); Rep=strings(0); Model=strings(0);
NFeat=[]; NObs=[]; TimeSec=[]; TimeStd=[];
for di = 1:nL
    fprintf('--- task %s ---\n', labels{di});
    for k = 1:numel(keys)
        tk = T{di,k};
        Family(end+1,1)=family; Task(end+1,1)=string(labels{di}); %#ok<AGROW>
        Rep(end+1,1)=reps(k); Model(end+1,1)=disp2(k); %#ok<AGROW>
        NFeat(end+1,1)=nFeat(di,k); NObs(end+1,1)=numel(tk); %#ok<AGROW>
        TimeSec(end+1,1)=mean(tk,'omitnan'); TimeStd(end+1,1)=std(tk,'omitnan'); %#ok<AGROW>
        fprintf('  %-5s %-16s dim=%5d  time=%8.4f +/- %7.4f s  (n=%d)\n', reps(k), disp2(k), nFeat(di,k), mean(tk,'omitnan'), std(tk,'omitnan'), numel(tk));
    end
end
% pooled across all tasks (kept for the family-average view)
for k = 1:numel(keys)
    tk = [T{:,k}]; nf_k = nFeat(:,k); nf_k = nf_k(~isnan(nf_k));
    Family(end+1,1)=family; Task(end+1,1)="ALL"; Rep(end+1,1)=reps(k); Model(end+1,1)=disp2(k); %#ok<AGROW>
    NFeat(end+1,1)=round(mean(nf_k)); NObs(end+1,1)=numel(tk); %#ok<AGROW>
    TimeSec(end+1,1)=mean(tk,'omitnan'); TimeStd(end+1,1)=std(tk,'omitnan'); %#ok<AGROW>
end

R = table(Family, Task, Rep, Model, NFeat, NObs, TimeSec, TimeStd);
outdir = fullfile(getenv('PNAS_ROOT'), 'results');
if ~isfolder(outdir), mkdir(outdir); end
out = char(fullfile(outdir, "model_runtime_" + family + ".csv"));
writetable(R, out);
fprintf('\nWritten: %s\n', out);
end

% ------------------------------------------------------------------
function tsec = fitTime(clf, D, p)
X = D.X_Train; Y = D.y_Train;
t = tic;
switch clf
    case "SVM"
        if p.svm.kernal, m = fitcsvm(X,Y,'KernelFunction','RBF','KernelScale','auto');
        else,            m = fitcsvm(X,Y); end
        m = fitSVMPosterior(m);
    case "MLP",      m = ConstructMLP(X, Y, p);
    case "ResNet3",  pp=p; pp.nn.resBlocks=3;  m = ConstructResNet(X, Y, pp);
    case "ResNet30", pp=p; pp.nn.resBlocks=30; m = ConstructResNet(X, Y, pp);
    case "RF",       m = fitcensemble(X,Y,'Method','Bag');
    case "GB",       m = fitcensemble(X,Y,'Method','LogitBoost');
    case "RUS",      m = fitcensemble(X,Y,'Method','RUSBoost');
    otherwise, error('unknown model %s', clf);
end
[~,~] = predict(m, D.X_Test_A);
[~,~] = predict(m, D.X_Test_B);
tsec = toc(t);
end

% ------------------------------------------------------------------
function lev = lookupLevel(accTab, ds, modelDisp)
% best-accuracy MLS level for (task ds, classifier modelDisp) from the acc CSV
lev = NaN;
if isempty(accTab), return; end
r = accTab(accTab.Dataset==string(ds) & accTab.Model==modelDisp & accTab.WithMLS==1, :);
if isempty(r), return; end
v = r.Level(1);
if iscell(v), v = v{1}; end
if isstring(v) || ischar(v), v = str2double(v); end
if ~isnan(v), lev = double(v); end
end
