function reproduce_semisyn()
% reproduce_semisyn  Command 3 of the reproduction package.
%
%   Reproduces the semisynthetic GCM experiment (appendix). Generates KL data from
%   GCM under the sin(15/18/20 x) deformations, Tumor training sizes 150..50,000
%   (Normal fixed at 100), and evaluates:
%     - radial-kernel SVM (MOS-KL vs original)        -> results_semisyn_v2_radial
%     - linear SVM + MLP + ResNet-3/-30 + baselines   -> results_semisyn_v2
%   then summarizes both into results/acc_semisyn_v2_radial.csv and
%   results/acc_semisyn_v2.csv (columns Sin,Size,Model,WithMLS,Level,Accuracy,
%   Sensitivity,Specificity,Precision,AUC) and draws the accuracy+precision scaling
%   figures results/figures/semisyn_v2_sin{15,18,20}_scaling.{pdf,png}.
%
%   FULL SCALE. This is very expensive: it runs SERIALLY and the 50,000-sample
%   generation peaks near ~180 GB of memory; the whole command takes on the order
%   of a day on a large-memory node. Do not run it on a laptop.
%
%   Run from the source/ folder after typing `paths`:
%       reproduce_semisyn

here = fileparts(mfilename('fullpath'));
setenv('PNAS_ROOT', here);
addpath(genpath(fullfile(here, 'Modules')));
addpath(genpath(fullfile(fileparts(here), 'toolboxes')));

if ~datasetPresent('GCM')
    error('GCM data not found at %s', fullfile(here, 'data', 'Tan_data-2', 'GCM.txt'));
end

fprintf('\n===== Semisynthetic GCM: radial-SVM sweep (all sins) =====\n');
RunSemiSynGCM_SVMradial();            % all sins, radial SVM only

fprintf('\n===== Semisynthetic GCM: linear SVM + NN + baselines (all sins) =====\n');
RunSemiSyntheticGCM_v2();             % all sins, sizes to 50,000

summarizeSemisyn('radial');
summarizeSemisyn('v2');
plotSemiSyntheticScalingV2();

fprintf('\nDone. Semisynthetic CSVs and figures are in %s\n', fullfile(here, 'results'));
end
