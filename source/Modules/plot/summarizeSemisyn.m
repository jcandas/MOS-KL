function summarizeSemisyn(variant)
% summarizeSemisyn  Extract the semisynthetic GCM accuracy table into
% results/acc_semisyn_v2.csv (variant 'v2', linear SVM + MLP + ResNet + baselines)
% or results/acc_semisyn_v2_radial.csv (variant 'radial', SVM only).
%
%   summarizeSemisyn('v2'); summarizeSemisyn('radial')
%
% Walks results_semisyn_v2[_radial]/.../<size>_TrainingA_100_TrainingB_10000_Testing/
% sin(<w>x)/{Balanced,Unbalanced}/ and, for each classifier, reports the MLS level
% that maximises its accuracy plus the matching benchmark. Sensitivity=recall and
% specificity are already oriented by FinalizeResults.
%
% Columns: Sin,Size,Model,WithMLS,Level,Accuracy,Sensitivity,Specificity,Precision,AUC

root = getenv('PNAS_ROOT');
assert(~isempty(root), 'PNAS_ROOT not set -- run ''paths'' from the source folder first.');

switch lower(string(variant))
    case "v2",     sub = 'results_semisyn_v2';        out = 'acc_semisyn_v2.csv';        svmVar = "SVM_Linear"; full = true;
    case "radial", sub = 'results_semisyn_v2_radial'; out = 'acc_semisyn_v2_radial.csv'; svmVar = "SVM_Radial"; full = false;
    otherwise, error('summarizeSemisyn: variant must be ''v2'' or ''radial''');
end

R = fullfile(root, sub, 'Manual_Hyperparameter_Selection', 'Synthetic', 'GCM');
sizes = {'150','450','1500','10000','50000'};
sins  = {'15','18','20'};
mlsMods  = {'SVM','SVM'; 'MLP','MLP'; 'ResNet3','ResNet-3'; 'ResNet30','ResNet-30'};
benchMap = {'MLP','MLP'; 'ResNet3','ResNet-3'; 'ResNet30','ResNet-30'; ...
            'Bag','Random Forest'; 'LogitBoost','Gradient Boosting'; 'RUSBoost','RUS Boost'};
if ~full, mlsMods = mlsMods(1,:); benchMap = cell(0,2); end   % radial run is SVM only

outdir = fullfile(root, 'results');
if ~isfolder(outdir), mkdir(outdir); end
fid = fopen(fullfile(outdir, out), 'w');
fprintf(fid, 'Sin,Size,Model,WithMLS,Level,Accuracy,Sensitivity,Specificity,Precision,AUC\n');

for si = 1:numel(sins)
    for zi = 1:numel(sizes)
        base = fullfile(R, [sizes{zi} '_TrainingA_100_TrainingB_10000_Testing'], ...
                        ['sin(' sins{si} 'x)']);

        d = dir(fullfile(base, 'Balanced', '*.mat'));
        assert(~isempty(d), 'No MLS .mat under %s', fullfile(base,'Balanced'));
        [~, ix] = max([d.datenum]);
        S = load(fullfile(d(ix).folder, d(ix).name), 'results'); r = S.results;
        sl = string(r.SlotLabels);
        for m = 1:size(mlsMods,1)
            idx = find(startsWith(sl, mlsMods{m,1} + "-L"));
            if isempty(idx), continue; end
            [~, bi] = max(r.accuracy(idx)); s = idx(bi);
            lv = erase(sl(s), mlsMods{m,1} + "-L");
            fprintf(fid, '%s,%s,%s,1,%s,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
                sins{si}, sizes{zi}, mlsMods{m,2}, lv, ...
                r.accuracy(s), r.recall(s), r.specificity(s), r.precision(s), r.AUC(s));
        end

        d = dir(fullfile(base, 'Unbalanced', '*.mat'));
        assert(~isempty(d), 'No Benchmark .mat under %s', fullfile(base,'Unbalanced'));
        [~, ix] = max([d.datenum]);
        S = load(fullfile(d(ix).folder, d(ix).name), 'results'); r = S.results;
        sl = string(r.SlotLabels);
        k = find(sl == svmVar, 1);
        fprintf(fid, '%s,%s,SVM,0,NaN,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
            sins{si}, sizes{zi}, r.accuracy(k), r.recall(k), r.specificity(k), r.precision(k), r.AUC(k));
        for m = 1:size(benchMap,1)
            k = find(sl == benchMap{m,1}, 1);
            if isempty(k), continue; end
            fprintf(fid, '%s,%s,%s,0,NaN,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
                sins{si}, sizes{zi}, benchMap{m,2}, ...
                r.accuracy(k), r.recall(k), r.specificity(k), r.precision(k), r.AUC(k));
        end
    end
end
fclose(fid);
fprintf('wrote %s\n', fullfile(outdir, out));
end
