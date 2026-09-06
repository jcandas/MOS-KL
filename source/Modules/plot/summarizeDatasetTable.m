function summarizeDatasetTable(family)
% summarizeDatasetTable  Extract the accuracy table for one dataset family from the
% saved classification .mat files into results/acc_<family>.csv.
%
%   summarizeDatasetTable('ADNI')
%
% For each label in the family it reads the MLS result (Balanced/) and the
% benchmark result (Unbalanced/) written by RunAllDatasets, and emits one row per
% (classifier, representation). For the MLS representation each classifier is
% reported at the level that MAXIMISES its accuracy (results.SlotLabels carry the
% per-level slots "SVM-L0", "MLP-L3", ...). Sensitivity (=results.recall) and
% specificity are taken directly, already oriented by FinalizeResults so that
% sensitivity is the detection rate of the more-severe class.
%
% Columns: Dataset,Model,WithMLS,Level,Accuracy,Sensitivity,Specificity,AUC,ModelTime

family = upper(string(family));
root = getenv('PNAS_ROOT');
assert(~isempty(root), 'PNAS_ROOT not set -- run ''paths'' from the source folder first.');
methods = DefineMethods;
R  = fullfile(root, 'results', 'Manual_Hyperparameter_Selection', 'Kfold');

switch family
    case "ADNI",  labels = methods.data.ADNI_files; mlsTag = 'Radial-Eigen-5';  svmVar = "SVM_Radial";
    case "CSF",   labels = methods.data.CSF_files;  mlsTag = 'Linear-Eigen-8';  svmVar = "SVM_Linear";
    case "NEWAD", labels = {'newAD'};               mlsTag = 'Linear-Eigen-8';  svmVar = "SVM_Linear";
    case "GCM",   labels = {'GCM'};                 mlsTag = 'Linear-Eigen-39'; svmVar = "SVM_Linear";
    otherwise, error('summarizeDatasetTable: family must be ADNI|CSF|newAD|GCM');
end

mlsMods  = {'SVM','SVM'; 'MLP','MLP'; 'ResNet3','ResNet-3'; 'ResNet30','ResNet-30'};
benchMap = {'MLP','MLP'; 'ResNet3','ResNet-3'; 'ResNet30','ResNet-30'; ...
            'Bag','Random Forest'; 'LogitBoost','Gradient Boosting'; 'RUSBoost','RUS Boost'};

outdir = fullfile(root, 'results');
if ~isfolder(outdir), mkdir(outdir); end
outCsv = fullfile(outdir, ['acc_' famName(family) '.csv']);   % acc_ADNI/CSF/newAD/GCM.csv
fid = fopen(outCsv, 'w');
fprintf(fid, 'Dataset,Model,WithMLS,Level,Accuracy,Sensitivity,Specificity,AUC,ModelTime\n');

for i = 1:numel(labels)
    L = labels{i};
    b = fullfile(R, L, 'Leave_10_out');

    % ---- MLS (Balanced): best-accuracy level per classifier ----
    d = dir(fullfile(b, 'Balanced', ['*' mlsTag '*.mat']));
    assert(~isempty(d), 'No MLS .mat for %s under %s', L, fullfile(b,'Balanced'));
    [~, ix] = max([d.datenum]);
    S = load(fullfile(d(ix).folder, d(ix).name), 'results'); r = S.results;
    sl = string(r.SlotLabels);
    for m = 1:size(mlsMods,1)
        idx = find(startsWith(sl, mlsMods{m,1} + "-L"));
        if isempty(idx), continue; end
        [~, bi] = max(r.accuracy(idx)); s = idx(bi);
        lv = erase(sl(s), mlsMods{m,1} + "-L");
        fprintf(fid, '%s,%s,1,%s,%.6f,%.6f,%.6f,%.6f,0\n', ...
            L, mlsMods{m,2}, lv, r.accuracy(s), r.recall(s), r.specificity(s), r.AUC(s));
    end

    % ---- Benchmark (Unbalanced): SVM + NN + ensemble baselines ----
    d = dir(fullfile(b, 'Unbalanced', '*Benchmark*.mat'));
    assert(~isempty(d), 'No Benchmark .mat for %s under %s', L, fullfile(b,'Unbalanced'));
    [~, ix] = max([d.datenum]);
    S = load(fullfile(d(ix).folder, d(ix).name), 'results'); r = S.results;
    sl = string(r.SlotLabels);
    si = find(sl == svmVar, 1);
    fprintf(fid, '%s,SVM,0,NaN,%.6f,%.6f,%.6f,%.6f,0\n', ...
        L, r.accuracy(si), r.recall(si), r.specificity(si), r.AUC(si));
    for m = 1:size(benchMap,1)
        si = find(sl == benchMap{m,1}, 1);
        if isempty(si), continue; end
        fprintf(fid, '%s,%s,0,NaN,%.6f,%.6f,%.6f,%.6f,0\n', ...
            L, benchMap{m,2}, r.accuracy(si), r.recall(si), r.specificity(si), r.AUC(si));
    end
end
fclose(fid);
fprintf('wrote %s (%d labels)\n', outCsv, numel(labels));
end

% ------------------------------------------------------------------
function s = famName(family)
% preserve the CSV filename casing used elsewhere (acc_ADNI/CSF/newAD/GCM.csv)
switch family
    case "ADNI",  s = 'ADNI';
    case "CSF",   s = 'CSF';
    case "NEWAD", s = 'newAD';
    case "GCM",   s = 'GCM';
    otherwise,    s = char(family);
end
end
