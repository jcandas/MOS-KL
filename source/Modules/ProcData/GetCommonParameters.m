function parameters = GetCommonParameters(parameters, methods)

% Data folders are resolved relative to the submission source root (set by
% running "paths" from the source/ folder). ADNI/CSF binaries are produced by
% PrepADNI.m / PrepCSF.m; GCM ships in data/Tan_data-2; newAD is private.
root = getenv('PNAS_ROOT');
assert(~isempty(root), 'PNAS_ROOT not set -- run ''paths'' from the source folder first.');

if ismember(parameters.data.label, methods.data.ADNI_files)
    parameters.data.path = [fullfile(root, 'data', 'ADNI_data') filesep];
    parameters.snapshots.k1 = 5;
elseif ismember(parameters.data.label, methods.data.CSF_files)
    parameters.data.path = [fullfile(root, 'data', 'CSF_data') filesep];
    parameters.snapshots.k1 = 8;
elseif strcmp(parameters.data.label, 'GCM')
    parameters.data.path = [fullfile(root, 'data', 'Tan_data-2') filesep];
    parameters.snapshots.k1 = 39;
elseif strcmp(parameters.data.label, 'newAD')
    parameters.data.path = [fullfile(root, 'data', 'newAD') filesep];
    parameters.snapshots.k1 = 8;
end

NAT(:,1) = string(methods.data.all_files)';
NAT(:,3) = ["Normal"; "CN"; ...
    "CN"; "LMCI"; "CN";...
    "CN"; "EMCI" ; "LMCI"; "CN"; "CN";"EMCI"];
NAT(:,2) = ["Tumor"; "AD";...
    "AD";"AD";"LMCI";...
    "AD";"AD";"AD";"EMCI";"LMCI";"LMCI"];

idx = strcmp(NAT(:,1), parameters.data.label);
parameters.data.nominal = char(NAT(idx,2));
parameters.data.anomalous = char(NAT(idx,3));

