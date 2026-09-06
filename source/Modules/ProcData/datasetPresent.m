function tf = datasetPresent(family)
% datasetPresent  True if the prepared data for a dataset family exists under the
% source root (PNAS_ROOT). Used by the reproduce_* wrappers to auto-skip datasets
% whose data has not been generated (e.g. private newAD).
root = getenv('PNAS_ROOT');
if isempty(root), tf = false; return; end
switch upper(string(family))
    case "ADNI",  f = fullfile(root, 'data', 'ADNI_data', 'Plasma_M12_ADCN.txt');
    case "CSF",   f = fullfile(root, 'data', 'CSF_data', 'SOMAscan7k_KNNimputed_AD_CN.txt');
    case "NEWAD", f = fullfile(root, 'data', 'newAD', 'newAD.txt');
    case "GCM",   f = fullfile(root, 'data', 'Tan_data-2', 'GCM.txt');
    otherwise, tf = false; return;
end
tf = isfile(f);
end
