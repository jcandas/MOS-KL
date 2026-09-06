function reproduce_accuracy()
% reproduce_accuracy  Command 1 of the reproduction package.
%
%   Reproduces the per-dataset accuracy tables. For each dataset whose prepared
%   data is present it runs the full leave-10-pairs-out pipeline (MLS + benchmark)
%   and summarizes the saved .mat files into results/acc_<dataset>.csv with
%   columns Dataset,Model,WithMLS,Level,Accuracy,Sensitivity,Specificity,AUC.
%
%   Datasets: ADNI (radial SVM, k1=5), CSF and newAD (linear SVM, k1=8) are the
%   paper tables; GCM (linear SVM, k1=39) is also summarized because command 2
%   (runtime) reads its per-classifier best levels from acc_GCM.csv. Missing data
%   folders are skipped automatically (newAD is private and not shipped).
%
%   Run from the source/ folder after typing `paths`:
%       reproduce_accuracy
%
%   May use the Parallel Computing Toolbox if available (falls back to serial).

here = fileparts(mfilename('fullpath'));
setenv('PNAS_ROOT', here);
addpath(genpath(fullfile(here, 'Modules')));
addpath(genpath(fullfile(fileparts(here), 'toolboxes')));

fams = {'ADNI', 'CSF', 'newAD'};
for i = 1:numel(fams)
    fam = fams{i};
    if ~datasetPresent(fam)
        fprintf('[skip] %s: prepared data not found -- run the Prep step first.\n', fam);
        continue;
    end
    fprintf('\n===== Accuracy: %s =====\n', fam);
    RunAllDatasets(fam);
    summarizeDatasetTable(fam);
end
fprintf('\nDone. Accuracy CSVs are in %s\n', fullfile(here, 'results'));
end
