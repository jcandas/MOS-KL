function parameters = GetCommonParameters2(parameters, methods)
% Alternate parameter set (unused by the reproduction commands). Data folders are
% resolved relative to the source root (PNAS_ROOT); see GetCommonParameters.
root = getenv('PNAS_ROOT');

if ismember(parameters.data.label, methods.data.ADNI_files)
    parameters.data.path = [fullfile(root, 'data', 'ADNI_data') filesep];
    parameters.snapshots.k1 = 5;
elseif ismember(parameters.data.label, methods.data.CSF_files)
    parameters.data.path = [fullfile(root, 'data', 'CSF_data') filesep];
    parameters.snapshots.k1 = 4;
elseif strcmp(parameters.data.label, 'GCM')
    parameters.data.path = [fullfile(root, 'data', 'Tan_data-2') filesep];
    parameters.snapshots.k1 = 19;
elseif strcmp(parameters.data.label, 'newAD')
    parameters.data.path = [fullfile(root, 'data', 'newAD') filesep];
    parameters.snapshots.k1 = 4;
end