function reproduce_runtime()
% reproduce_runtime  Command 2 of the reproduction package.
%
%   Reproduces the per-model fit+predict runtime results. For each dataset with
%   prepared data it times every classifier (MOS-KL and original features) over 30
%   leave-pair-out folds and writes results/model_runtime_<dataset>.csv plus a bar
%   figure results/figures/<dataset>_runtime.{pdf,png}.
%
%   This is a SEPARATE, SINGLE-CORE, SERIAL run (maxNumCompThreads(1), no parfor)
%   so the timings are fair and independent of machine load. Run it AFTER
%   reproduce_accuracy -- it reads results/acc_<dataset>.csv for the per-classifier
%   best MLS levels (falls back to the deepest level with a warning if absent). Run
%   it alone, with the machine otherwise idle.
%
%   Run from the source/ folder after typing `paths`:
%       reproduce_runtime

here = fileparts(mfilename('fullpath'));
setenv('PNAS_ROOT', here);
addpath(genpath(fullfile(here, 'Modules')));
addpath(genpath(fullfile(fileparts(here), 'toolboxes')));
delete(gcp('nocreate'));          % ensure no pool interferes with timing
maxNumCompThreads(1);             % single-core for fair, exact measurement

fams = {'ADNI', 'CSF', 'newAD'};
first = true;
for i = 1:numel(fams)
    fam = fams{i};
    if ~datasetPresent(fam)
        fprintf('[skip] %s: prepared data not found.\n', fam);
        continue;
    end
    if ~isfile(fullfile(here, 'results', ['acc_' fam '.csv']))
        warning('acc_%s.csv not found -- run reproduce_accuracy first; timing will use the deepest level.', fam);
    end
    fprintf('\n===== Runtime: %s =====\n', fam);
    MeasureModelTime(fam, 30);           % 30 folds, serial
    plotModelRuntime(fam, ~first);       % first panel keeps legend + y-axis label
    first = false;
end
fprintf('\nDone. Runtime CSVs and figures are in %s\n', fullfile(here, 'results'));
end
